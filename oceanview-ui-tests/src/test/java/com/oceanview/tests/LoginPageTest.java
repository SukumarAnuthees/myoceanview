package com.oceanview.tests;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.time.Duration;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LoginPageTest {

    private WebDriver driver;
    private WebDriverWait wait;

    private final String BASE_URL = "http://localhost:8081/ocean_view/login.jsp";

    @BeforeEach
    void setup() {
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver();
        driver.manage().window().maximize();

        wait = new WebDriverWait(driver, Duration.ofSeconds(10));
        driver.get(BASE_URL);
    }

    @AfterEach
    void tearDown() {
        if (driver != null) driver.quit();
    }

    private WebElement usernameField() {
        return driver.findElement(By.name("username"));
    }

    private WebElement passwordField() {
        return driver.findElement(By.name("password"));
    }

    private WebElement submitButton() {
        return driver.findElement(By.cssSelector("button[type='submit']"));
    }

    @Test
    @Order(1)
    void testLoginPageLoads() {
        Assertions.assertTrue(driver.getTitle().contains("Sign In"));
        Assertions.assertTrue(usernameField().isDisplayed());
        Assertions.assertTrue(passwordField().isDisplayed());
        Assertions.assertTrue(submitButton().isDisplayed());
    }

    @Test
    @Order(2)
    void testInvalidLoginShowsError() {
        usernameField().sendKeys("wrongUser");
        passwordField().sendKeys("wrongPass");
        submitButton().click();

        WebElement errorDiv = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".error"))
        );

        Assertions.assertTrue(errorDiv.getText().contains("Invalid Username or Password"));
    }
}