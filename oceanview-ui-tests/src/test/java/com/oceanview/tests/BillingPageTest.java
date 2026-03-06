package com.oceanview.tests;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class BillingPageTest {

    private WebDriver driver;
    private WebDriverWait wait;

    // ✅ Change these to your correct URLs
    private final String LOGIN_URL   = "http://localhost:8081/ocean_view/login.jsp";
    private final String BILLING_URL = "http://localhost:8081/ocean_view/billing.jsp";

    // ✅ Use a valid account from your DB
    private final String VALID_USER = "admin";
    private final String VALID_PASS = "ocean2026";

    @BeforeEach
    void setup() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().window().maximize();
        wait = new WebDriverWait(driver, Duration.ofSeconds(10));

        // ✅ Login first because billing.jsp requires session
        doLogin();
    }

    @AfterEach
    void tearDown() {
        if (driver != null) driver.quit();
    }

    // ---------------- Helpers (match your style) ----------------

    private void doLogin() {
        driver.get(LOGIN_URL);

        // Same locators as your LoginPageTest
        driver.findElement(By.name("username")).sendKeys(VALID_USER);
        driver.findElement(By.name("password")).sendKeys(VALID_PASS);
        driver.findElement(By.cssSelector("button[type='submit']")).click();

        // Wait any page load (dashboard/welcome etc.)
        wait.until(ExpectedConditions.presenceOfElementLocated(By.tagName("body")));
    }

    private WebElement reservationInput() {
        return driver.findElement(By.name("q"));
    }

    private WebElement searchButton() {
        return driver.findElement(By.cssSelector("button.btn[type='submit']"));
    }

    private boolean billAreaExists() {
        return driver.findElements(By.id("billArea")).size() > 0;
    }

    private double parseMoney(String value) {
        // "66,000" -> 66000
        return Double.parseDouble(value.replace(",", "").trim());
    }

    // ---------------- Tests ----------------

    @Test
    @Order(1)
    void testBillingPageLoads() {
        driver.get(BILLING_URL);

        Assertions.assertTrue(driver.getTitle().toLowerCase().contains("billing"));
        Assertions.assertTrue(reservationInput().isDisplayed());
        Assertions.assertTrue(searchButton().isDisplayed());

        // Should show helper message when not searched
        WebElement infoMsg = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".msg.ok"))
        );
        Assertions.assertTrue(infoMsg.getText().toLowerCase().contains("enter a reservation id"));
    }

    @Test
    @Order(2)
    void testEmptySearchShowsInfoMessage() {
        driver.get(BILLING_URL);

        // Click search without typing
        searchButton().click();

        // Your page shows info message when not found & not searched
        WebElement infoMsg = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".msg.ok"))
        );
        Assertions.assertTrue(infoMsg.getText().toLowerCase().contains("enter a reservation id"));
    }

    @Test
    @Order(3)
    void testInvalidReservationShowsError() {
        driver.get(BILLING_URL);

        reservationInput().sendKeys("INVALID-99999");
        searchButton().click();

        WebElement errorMsg = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".msg.err"))
        );

        Assertions.assertTrue(errorMsg.getText().toLowerCase().contains("no reservation found"));
        Assertions.assertFalse(billAreaExists(), "Bill area should not show for invalid search");
    }

    @Test
    @Order(4)
    void testValidReservationShowsBill() {
        driver.get(BILLING_URL);

        // ✅ This must exist in your DB
        reservationInput().sendKeys("RES-001");
        searchButton().click();

        // Bill should appear
        wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("billArea")));
        Assertions.assertTrue(billAreaExists());

        // Tag should show RES-xxx
        WebElement tag = driver.findElement(By.cssSelector(".tag"));
        Assertions.assertTrue(tag.getText().startsWith("RES-"));

        // Check totals are visible (not empty)
        WebElement totalDiv = driver.findElement(By.xpath("//div[contains(@class,'row total')]/div"));
        Assertions.assertFalse(totalDiv.getText().trim().isEmpty());
    }

    @Test
    @Order(5)
    void testBillingMathDynamic_NoHardcode() {

        driver.get(BILLING_URL);

        reservationInput().sendKeys("RES-001");
        searchButton().click();

        wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("billArea")));
        Assertions.assertTrue(billAreaExists(), "Bill should show for RES-001");

        // ✅ Read room type from UI
        String roomType = driver.findElement(By.xpath(
                "//div[contains(@class,'box')]//div[@class='k' and text()='Room Type']/following-sibling::div"
        )).getText().trim();

        // ✅ Same rate mapping as billing.jsp
        double expectedRate;
        switch (roomType) {
            case "Ocean Suite"   -> expectedRate = 20000.0;
            case "Beach Villa"   -> expectedRate = 30000.0;
            case "Deluxe Room"   -> expectedRate = 15000.0;
            case "Standard Room" -> expectedRate = 10000.0;
            default              -> expectedRate = 12000.0; // fallback like JSP
        }

        // ✅ Read nights from UI text "• 3 night(s)"
        String stayText = driver.findElement(By.xpath(
                "//div[contains(@class,'box')]//div[@class='k' and text()='Stay']/following-sibling::div"
        )).getText();

        // Extract number before "night"
        int nights = 1;
        try {
            // Example: "... • 3 night(s)"
            String[] parts = stayText.split("•");
            String last = parts[parts.length - 1].trim(); // "3 night(s)"
            nights = Integer.parseInt(last.split(" ")[0].replaceAll("[^0-9]", ""));
            if (nights < 1) nights = 1;
        } catch (Exception ignore) {}

        double rateUI = parseMoney(driver.findElement(
                By.xpath("//div[contains(@class,'row')][.//span[contains(text(),'Rate')]]/div")
        ).getText());

        double subtotalUI = parseMoney(driver.findElement(
                By.xpath("//div[contains(@class,'row')][.//span[contains(text(),'Subtotal')]]/div")
        ).getText());

        double serviceUI = parseMoney(driver.findElement(
                By.xpath("//div[contains(@class,'row')][.//span[contains(text(),'Service Charge')]]/div")
        ).getText());

        double totalUI = parseMoney(driver.findElement(
                By.xpath("//div[contains(@class,'row total')]/div")
        ).getText());

        // ✅ Expected calculations (same as JSP)
        double expectedSubtotal = expectedRate * nights;
        double expectedService = expectedSubtotal * 0.10;
        double expectedTotal = expectedSubtotal + expectedService;

        Assertions.assertEquals(expectedRate, rateUI, 0.01, "Rate per night mismatch");
        Assertions.assertEquals(expectedSubtotal, subtotalUI, 0.01, "Subtotal mismatch");
        Assertions.assertEquals(expectedService, serviceUI, 0.01, "Service charge mismatch");
        Assertions.assertEquals(expectedTotal, totalUI, 0.01, "Total mismatch");
    }
    @Test
    @Order(6)
    void testBackToReservationsButton() {
        driver.get(BILLING_URL);

        reservationInput().sendKeys("RES-001");
        searchButton().click();

        wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("billArea")));

        WebElement backBtn = wait.until(
                ExpectedConditions.elementToBeClickable(
                        By.xpath("//button[contains(@class,'btn') and contains(.,'Back to Reservations')]")
                )
        );

        backBtn.click();

        Assertions.assertTrue(driver.getCurrentUrl().toLowerCase().contains("reservations.jsp"));
    }

    @Test
    @Order(7)
    void testPrintButtonExists_NoClick() {
        driver.get(BILLING_URL);

        reservationInput().sendKeys("RES-001");
        searchButton().click();

        wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("billArea")));

        WebElement printBtn = wait.until(
                ExpectedConditions.visibilityOfElementLocated(
                        By.xpath("//button[contains(@class,'btn-ghost') and contains(.,'Print Bill')]")
                )
        );

        // ✅ Verify only (DO NOT click window.print)
        Assertions.assertTrue(printBtn.isDisplayed());
        Assertions.assertTrue(printBtn.isEnabled());
        Assertions.assertTrue(printBtn.getText().contains("Print Bill"));
    }
}