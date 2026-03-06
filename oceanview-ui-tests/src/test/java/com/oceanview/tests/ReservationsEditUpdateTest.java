package com.oceanview.tests;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.*;

import java.time.Duration;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class ReservationsEditUpdateTest {

    private WebDriver driver;
    private WebDriverWait wait;

    // ✅ URLs
    private final String LOGIN_URL = "http://localhost:8081/ocean_view/login.jsp";
    private final String RES_URL   = "http://localhost:8081/ocean_view/reservations.jsp";

    // ✅ Valid credentials (change if needed)
    private final String VALID_USER = "admin";
    private final String VALID_PASS = "ocean2026";

    @BeforeEach
    void setup() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().window().maximize();

        wait = new WebDriverWait(driver, Duration.ofSeconds(15));

        doLogin();
        driver.get(RES_URL);
        wait.until(ExpectedConditions.presenceOfElementLocated(By.tagName("body")));
    }

    @AfterEach
    void tearDown() {
        if (driver != null) driver.quit();
    }

    // ==========================================================
    // ✅ HELPERS
    // ==========================================================

    private void doLogin() {
        driver.get(LOGIN_URL);

        WebElement u = driver.findElement(By.name("username"));
        WebElement p = driver.findElement(By.name("password"));
        WebElement btn = driver.findElement(By.cssSelector("button[type='submit']"));

        u.clear(); u.sendKeys(VALID_USER);
        p.clear(); p.sendKeys(VALID_PASS);
        btn.click();

        wait.until(ExpectedConditions.presenceOfElementLocated(By.tagName("body")));
    }

    private WebElement firstEditButton() {
        // ✏️ Edit button inside first card
        return driver.findElement(By.cssSelector(".card .actions .act-btn.light"));
    }

    private WebElement modalBackdrop() {
        return driver.findElement(By.id("editModal"));
    }

    private boolean isModalOpen() {
        try {
            return "flex".equalsIgnoreCase(modalBackdrop().getCssValue("display"));
        } catch (Exception e) {
            return false;
        }
    }

    private void openFirstEditModal() {
        wait.until(ExpectedConditions.elementToBeClickable(firstEditButton())).click();

        // modal becomes display:flex
        wait.until(d -> isModalOpen());

        // wait until a modal field visible
        wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("mGuest")));
    }

    private void closeModal() {
        driver.findElement(By.cssSelector("#editModal .modal-close")).click();
        wait.until(d -> !isModalOpen());
    }

    /**
     * ✅ Fill edit form reliably
     * - Guest name: letters only (matches your regex)
     * - Contact: valid Sri Lanka
     * - Dates: set via JS to avoid invalid date format issue
     */
    private void fillEditForm(String guest, String contact, String address,
                              String roomType, String checkIn, String checkOut) {

        WebElement mGuest   = driver.findElement(By.id("mGuest"));
        WebElement mContact = driver.findElement(By.id("mContact"));
        WebElement mAddress = driver.findElement(By.id("mAddress"));
        WebElement mRoom    = driver.findElement(By.id("mRoom"));

        mGuest.clear();
        mGuest.sendKeys(guest);

        mContact.clear();
        mContact.sendKeys(contact);

        mAddress.clear();
        mAddress.sendKeys(address);

        new Select(mRoom).selectByVisibleText(roomType);

        // ✅ Set <input type="date"> values using JavaScript (MOST STABLE)
        JavascriptExecutor js = (JavascriptExecutor) driver;

        js.executeScript("document.getElementById('mIn').value = arguments[0];", checkIn);
        js.executeScript("document.getElementById('mOut').value = arguments[0];", checkOut);

        // ✅ Trigger events so validations read updated values
        js.executeScript(
                "document.getElementById('mIn').dispatchEvent(new Event('input',{bubbles:true}));" +
                "document.getElementById('mIn').dispatchEvent(new Event('change',{bubbles:true}));" +
                "document.getElementById('mOut').dispatchEvent(new Event('input',{bubbles:true}));" +
                "document.getElementById('mOut').dispatchEvent(new Event('change',{bubbles:true}));"
        );

        // ✅ Ensure values are actually set before submit
        String inV  = driver.findElement(By.id("mIn")).getAttribute("value");
        String outV = driver.findElement(By.id("mOut")).getAttribute("value");

        Assertions.assertEquals(checkIn, inV,  "Check-in date not set correctly");
        Assertions.assertEquals(checkOut, outV, "Check-out date not set correctly");
    }

    private void clickUpdate() {
        WebElement saveBtn = driver.findElement(By.cssSelector("#editModal button.m-btn.save"));
        wait.until(ExpectedConditions.elementToBeClickable(saveBtn)).click();
    }

    // ✅ Handle JS alert (client-side validation)
    private String acceptAlertIfPresent() {
        try {
            WebDriverWait shortWait = new WebDriverWait(driver, Duration.ofSeconds(2));
            Alert alert = shortWait.until(ExpectedConditions.alertIsPresent());
            String text = alert.getText();
            alert.accept();
            return text;
        } catch (Exception e) {
            return null;
        }
    }

    // ✅ Wait and return either OK or ERR server message (after POST)
    private String waitForOkOrErrMessage() {
        By ok  = By.cssSelector(".alert.ok");
        By err = By.cssSelector(".alert.err");

        WebElement msg = wait.until(d -> {
            java.util.List<WebElement> okList = d.findElements(ok);
            if (!okList.isEmpty() && okList.get(0).isDisplayed()) return okList.get(0);

            java.util.List<WebElement> errList = d.findElements(err);
            if (!errList.isEmpty() && errList.get(0).isDisplayed()) return errList.get(0);

            return null;
        });

        return msg.getText().trim();
    }

    // Helper: random letters for uniqueness (NO digits)
    private String lettersOnlySuffix(int len) {
        String alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        StringBuilder sb = new StringBuilder();
        java.util.Random r = new java.util.Random();
        for (int i = 0; i < len; i++) sb.append(alpha.charAt(r.nextInt(alpha.length())));
        return sb.toString();
    }

    // ==========================================================
    // ✅ TESTS
    // ==========================================================

    @Test
    @Order(1)
    void testReservationsPageLoads() {
        Assertions.assertTrue(driver.getTitle().toLowerCase().contains("reservations"));
        Assertions.assertTrue(driver.findElements(By.cssSelector(".card")).size() > 0,
                "Reservation cards should be visible");
    }

    @Test
    @Order(2)
    void testEditModalOpens() {
        openFirstEditModal();
        Assertions.assertTrue(isModalOpen(), "Edit modal should open");
        Assertions.assertTrue(driver.findElement(By.id("mGuest")).isDisplayed());
        Assertions.assertTrue(driver.findElement(By.id("mContact")).isDisplayed());
        closeModal();
    }

    @Test
    @Order(3)
    void testUpdateValidData_ShowsSuccess() {
        openFirstEditModal();

        // ✅ letters only unique name (NO numbers)
        String uniqueName = "Kasun Perera " + lettersOnlySuffix(6);

        // ✅ Valid data that matches your validations
        fillEditForm(
                uniqueName,
                "0771234567",
                "Colombo 01, Sri Lanka",
                "Deluxe Room",
                "2026-03-10",
                "2026-03-12"
        );

        clickUpdate();

        // If client alert appears, update did not submit
        String alertText = acceptAlertIfPresent();
        if (alertText != null) {
            Assertions.fail("Client-side validation blocked submit: " + alertText);
        }

        String msg = waitForOkOrErrMessage();

        if (msg.toLowerCase().contains("updated successfully")) {
            Assertions.assertTrue(driver.getPageSource().contains(uniqueName),
                    "Updated guest name should appear on the page");
        } else {
            Assertions.fail("Update failed. Server message: " + msg);
        }
    }

    @Test
    @Order(4)
    void testInvalidGuestName_ShowsAlert() {
        openFirstEditModal();

        fillEditForm(
                "1",                 // invalid
                "0771234567",
                "Test Address",
                "Standard Room",
                "2026-03-10",
                "2026-03-11"
        );

        clickUpdate();

        String alertText = acceptAlertIfPresent();
        Assertions.assertNotNull(alertText, "Expected alert for invalid guest name");
        Assertions.assertTrue(alertText.toLowerCase().contains("guest name"));
    }

    @Test
    @Order(5)
    void testInvalidContact_ShowsAlert() {
        openFirstEditModal();

        fillEditForm(
                "Nimal Silva",
                "12345",             // invalid
                "Test Address",
                "Ocean Suite",
                "2026-03-10",
                "2026-03-11"
        );

        clickUpdate();

        String alertText = acceptAlertIfPresent();
        Assertions.assertNotNull(alertText, "Expected alert for invalid contact");
        Assertions.assertTrue(alertText.toLowerCase().contains("contact"));
    }

    @Test
    @Order(6)
    void testInvalidDates_ShowsAlert() {
        openFirstEditModal();

        fillEditForm(
                "Nimal Silva",
                "0771234567",
                "Test Address",
                "Ocean Suite",
                "2026-03-10",
                "2026-03-10"         // invalid
        );

        clickUpdate();

        String alertText = acceptAlertIfPresent();
        Assertions.assertNotNull(alertText, "Expected alert for invalid dates");
        Assertions.assertTrue(alertText.toLowerCase().contains("check out"));
    }

    @Test
    @Order(7)
    void testServerSideValidation_BypassClientJS_SubmitDirect() {
        openFirstEditModal();

        // invalid guest name length (<3) - server should reject
        fillEditForm(
                "AA",
                "0771234567",
                "Test Address",
                "Ocean Suite",
                "2026-03-10",
                "2026-03-11"
        );

        // ✅ bypass JS submit handler (force server validation)
        ((JavascriptExecutor) driver).executeScript(
                "document.querySelector('#editModal form').submit();"
        );

        String msg = waitForOkOrErrMessage();
        Assertions.assertTrue(msg.toLowerCase().contains("guest name"),
                "Server-side error should mention Guest Name. Actual: " + msg);
    }
}