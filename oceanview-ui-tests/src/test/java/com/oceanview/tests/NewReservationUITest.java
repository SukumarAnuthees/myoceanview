package com.oceanview.tests;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.*;

import java.sql.*;
import java.sql.Date;
import java.time.Duration;
import java.time.LocalDate;
import java.util.*;
import java.util.regex.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class NewReservationUITest {

    private WebDriver driver;
    private WebDriverWait wait;

    // ✅ URLs
    private final String BASE_URL  = "http://localhost:8081/ocean_view";
    private final String LOGIN_URL = BASE_URL + "/login.jsp";
    private final String RES_URL   = BASE_URL + "/new_reservation.jsp";

    // ✅ Login user
    private final String USERNAME = "admin";
    private final String PASSWORD = "ocean2026";

    // ✅ DB
    private static final String DB_URL  = "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    private String createdContact1;
    private String createdContact2;

    @BeforeEach
    void setUp() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(0));
        driver.manage().window().maximize();
        wait = new WebDriverWait(driver, Duration.ofSeconds(12));

        ensureLoggedIn();
        openReservationPageStrict();
    }

    @AfterEach
    void tearDown() {
        if (createdContact1 != null) deleteReservationByContact(createdContact1);
        if (createdContact2 != null) deleteReservationByContact(createdContact2);
        if (driver != null) driver.quit();
    }

    // =========================================================
    // LOGIN + OPEN
    // =========================================================
    private void ensureLoggedIn() {
        driver.get(LOGIN_URL);

        // already logged in if redirected away from login.jsp
        if (!driver.getCurrentUrl().toLowerCase().contains("login")) return;

        safeType(By.name("username"), USERNAME);
        safeType(By.name("password"), PASSWORD);

        safeClick(By.cssSelector("button, input[type='submit']"));
        wait.until(d -> !d.getCurrentUrl().toLowerCase().contains("login"));
    }

    private void openReservationPageStrict() {
        driver.get(RES_URL);

        // session missing -> back to login -> login -> retry
        if (driver.getCurrentUrl().toLowerCase().contains("login")) {
            ensureLoggedIn();
            driver.get(RES_URL);
        }

        try {
            wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("guestName")));
            wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("submitBtn")));
        } catch (TimeoutException ex) {
            failWithDebug("Cannot open new_reservation.jsp (guestName/submitBtn not found).");
        }
    }

    // =========================================================
    // UI HELPERS (match your IDs)
    // =========================================================
    private void safeType(By by, String text) {
        WebElement el = wait.until(ExpectedConditions.elementToBeClickable(by));
        el.clear();
        el.sendKeys(text);

        // trigger JS validation
        try {
            ((JavascriptExecutor) driver).executeScript(
                    "arguments[0].dispatchEvent(new Event('input',{bubbles:true}));", el
            );
        } catch (Exception ignored) {}
    }

    private void safeClick(By by) {
        wait.until(ExpectedConditions.elementToBeClickable(by)).click();
    }

    private void selectRoomType(String visibleText) {
        WebElement sel = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("roomType")));
        new Select(sel).selectByVisibleText(visibleText);

        try {
            ((JavascriptExecutor) driver).executeScript(
                    "document.getElementById('roomType').dispatchEvent(new Event('change',{bubbles:true}));"
            );
        } catch (Exception ignored) {}
    }

    private void setDateISO(String elementId, LocalDate date) {
        String iso = date.toString();
        ((JavascriptExecutor) driver).executeScript(
                "const el=document.getElementById(arguments[0]);" +
                        "el.value=arguments[1];" +
                        "el.dispatchEvent(new Event('input',{bubbles:true}));" +
                        "el.dispatchEvent(new Event('change',{bubbles:true}));",
                elementId, iso
        );
    }

    private void setDates(LocalDate in, LocalDate out) {
        setDateISO("checkIn", in);

        // your page has enforceCheckoutMin()
        try {
            ((JavascriptExecutor) driver).executeScript(
                    "if(window.enforceCheckoutMin){ enforceCheckoutMin(); }"
            );
        } catch (Exception ignored) {}

        setDateISO("checkOut", out);

        // refresh datePanel if validateDates exists
        try {
            ((JavascriptExecutor) driver).executeScript(
                    "if(window.validateDates){ validateDates(); }"
            );
        } catch (Exception ignored) {}
    }

    private void fillForm(String guestName, String contact, String address,
                          String roomType, LocalDate in, LocalDate out) {

        safeType(By.id("guestName"), guestName);
        safeType(By.id("contact"), contact);
        safeType(By.id("address"), address);
        selectRoomType(roomType);
        setDates(in, out);
    }

    private void submitAndWaitOutcome() {
        String oldUrl = driver.getCurrentUrl();

        WebElement btn = wait.until(ExpectedConditions.elementToBeClickable(By.id("submitBtn")));
        ((JavascriptExecutor) driver).executeScript("arguments[0].click();", btn);

        WebDriverWait w = new WebDriverWait(driver, Duration.ofSeconds(12));
        try {
            w.until(d -> {
                if (!d.getCurrentUrl().equals(oldUrl)) return true;
                if (d.findElements(By.cssSelector(".msg.ok")).size() > 0) return true;
                if (d.findElements(By.cssSelector(".msg.err")).size() > 0) return true;
                return false;
            });
        } catch (TimeoutException ex) {
            failWithDebug("After submit, no .msg.ok or .msg.err appeared.");
        }
    }

    private Optional<String> successMsg() {
        try {
            String t = driver.findElement(By.cssSelector(".msg.ok")).getText().trim();
            return t.isEmpty() ? Optional.empty() : Optional.of(t);
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private Optional<String> errorMsg() {
        try {
            String t = driver.findElement(By.cssSelector(".msg.err")).getText().trim();
            return t.isEmpty() ? Optional.empty() : Optional.of(t);
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    private String textOrEmpty(String id) {
        try { return driver.findElement(By.id(id)).getText().trim(); }
        catch (Exception e) { return ""; }
    }

    private void failWithDebug(String msg) {
        String html = driver.getPageSource();
        html = html.substring(0, Math.min(1200, html.length()));

        Assertions.fail(msg + "\n"
                + "URL: " + driver.getCurrentUrl() + "\n"
                + "Title: " + driver.getTitle() + "\n"
                + "msg.ok: " + successMsg().orElse("") + "\n"
                + "msg.err: " + errorMsg().orElse("") + "\n"
                + "guestName_err: " + textOrEmpty("guestName_err") + "\n"
                + "contact_err: " + textOrEmpty("contact_err") + "\n"
                + "address_err: " + textOrEmpty("address_err") + "\n"
                + "roomType_err: " + textOrEmpty("roomType_err") + "\n"
                + "checkIn_err: " + textOrEmpty("checkIn_err") + "\n"
                + "checkOut_err: " + textOrEmpty("checkOut_err") + "\n"
                + "datePanel: " + textOrEmpty("datePanel") + "\n"
                + "HTML snippet:\n" + html);
    }

    // =========================================================
    // DB HELPERS (stable tests)
    // =========================================================
    private Connection db() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    private void deleteReservationByContact(String contact) {
        String sql = "DELETE FROM reservations WHERE contact = ?";
        try (Connection con = db(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, contact.replaceAll("\\s+",""));
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private ReservationRow findReservationByContact(String contact) {
        String sql = "SELECT id,reservation_code,guest_name,contact,room_type,check_in,check_out " +
                     "FROM reservations WHERE contact=? ORDER BY id DESC LIMIT 1";
        try (Connection con = db(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, contact.replaceAll("\\s+",""));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ReservationRow r = new ReservationRow();
                    r.id = rs.getLong("id");
                    r.reservationCode = rs.getString("reservation_code");
                    r.guestName = rs.getString("guest_name");
                    r.roomType = rs.getString("room_type");
                    r.checkIn = rs.getDate("check_in").toLocalDate();
                    r.checkOut = rs.getDate("check_out").toLocalDate();
                    return r;
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("DB read failed: " + e.getMessage(), e);
        }
        return null;
    }

    private static class ReservationRow {
        long id;
        String reservationCode;
        String guestName;
        String roomType;
        LocalDate checkIn;
        LocalDate checkOut;
    }

    private static class DateRange {
        LocalDate in;
        LocalDate out;
        DateRange(LocalDate in, LocalDate out){ this.in=in; this.out=out; }
    }

    // ✅ Find a free date range for a room type (prevents random “already booked” failures)
    private DateRange findAvailableRange(String roomType, LocalDate startFrom, int nights) {
        if (nights < 1) nights = 1;
        if (nights > 30) nights = 30;

        String sql = "SELECT check_in, check_out FROM reservations " +
                "WHERE room_type=? AND check_out > ? ORDER BY check_in ASC";

        List<DateRange> booked = new ArrayList<>();
        try (Connection con = db(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, roomType);
            ps.setDate(2, Date.valueOf(startFrom));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LocalDate in  = rs.getDate("check_in").toLocalDate();
                    LocalDate out = rs.getDate("check_out").toLocalDate();
                    booked.add(new DateRange(in, out));
                }
            }
        } catch (Exception e) {
            throw new RuntimeException("DB scan failed: " + e.getMessage(), e);
        }

        LocalDate candidateIn = startFrom;
        while (true) {
            LocalDate candidateOut = candidateIn.plusDays(nights);

            boolean overlap = false;
            for (DateRange b : booked) {
                if (candidateIn.isBefore(b.out) && candidateOut.isAfter(b.in)) {
                    candidateIn = b.out; // jump forward
                    overlap = true;
                    break;
                }
            }
            if (!overlap) return new DateRange(candidateIn, candidateOut);

            if (candidateIn.isAfter(LocalDate.now().plusDays(365))) {
                throw new RuntimeException("No free dates found for " + roomType + " within 365 days.");
            }
        }
    }

    private String randomSLContact() {
        int n = (int)(Math.random() * 9000000) + 1000000;
        return "077" + n; // matches your JS ^0\d{9}$
    }

    private String extractReservationCode(String text) {
        Pattern p = Pattern.compile("(RES-\\d{3,})");
        Matcher m = p.matcher(text);
        return m.find() ? m.group(1) : null;
    }

    private String randomLetters(int len) {
        String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < len; i++) {
            sb.append(alphabet.charAt((int)(Math.random()*alphabet.length())));
        }
        return sb.toString();
    }

    // =========================================================
    // TESTS
    // =========================================================

    @Test
    @Order(1)
    void createReservation_shouldShowSuccess_andInsertDB() {
        createdContact1 = randomSLContact();
        String roomType = "Ocean Suite";

        // ✅ stable: find free slot
        DateRange range = findAvailableRange(roomType, LocalDate.now().plusDays(2), 2);

        String guestName = "UITest " + randomLetters(6);

        fillForm(guestName, createdContact1, "No 20, Galle Road, Colombo", roomType, range.in, range.out);
        submitAndWaitOutcome();

        if (errorMsg().isPresent()) {
            failWithDebug("Expected success but got error: " + errorMsg().get());
        }

        String ok = successMsg().orElse(null);
        if (ok == null) failWithDebug("Expected .msg.ok but none appeared.");

        String uiCode = extractReservationCode(ok);
        Assertions.assertNotNull(uiCode, "No RES-xxx found in success message: " + ok);

        ReservationRow row = findReservationByContact(createdContact1);
        Assertions.assertNotNull(row, "Reservation not found in DB for contact: " + createdContact1);

        Assertions.assertEquals(guestName, row.guestName);
        Assertions.assertEquals(roomType, row.roomType);
        Assertions.assertEquals(range.in, row.checkIn);
        Assertions.assertEquals(range.out, row.checkOut);
        Assertions.assertEquals(uiCode, row.reservationCode);
    }

    @Test
    @Order(2)
    void overlapBooking_sameRoomType_shouldShowServerError_andNotInsertSecondRow() {
        String roomType = "Beach Villa";

        // ✅ first booking uses free range
        createdContact1 = randomSLContact();
        DateRange first = findAvailableRange(roomType, LocalDate.now().plusDays(5), 2);

        fillForm("First Guest", createdContact1, "No 11, Colombo Main Road", roomType, first.in, first.out);
        submitAndWaitOutcome();

        if (errorMsg().isPresent()) {
            failWithDebug("First booking failed unexpectedly: " + errorMsg().get());
        }

        // ✅ second booking overlaps intentionally
        createdContact2 = randomSLContact();
        LocalDate in2  = first.in.plusDays(1);
        LocalDate out2 = first.out.plusDays(1);

        openReservationPageStrict();
        fillForm("Second Guest", createdContact2, "No 22, Colombo Main Road", roomType, in2, out2);
        submitAndWaitOutcome();

        String err = errorMsg().orElse(null);
        if (err == null) failWithDebug("Expected overlap .msg.err but none appeared.");

        Assertions.assertTrue(err.toLowerCase().contains("already booked"),
                "Expected overlap error, got: " + err);

        ReservationRow second = findReservationByContact(createdContact2);
        Assertions.assertNull(second, "Second reservation should NOT be inserted due to overlap.");
    }
}