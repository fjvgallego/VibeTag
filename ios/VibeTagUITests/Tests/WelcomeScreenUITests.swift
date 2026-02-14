import XCTest

@MainActor
final class WelcomeScreenUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITests()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Content

    func test_welcomeScreen_showsAppTitle() {
        XCTAssertTrue(app.staticTexts["VibeTag"].waitForExistence(timeout: 5))
    }

    func test_welcomeScreen_showsConnectAppleMusicButton() {
        XCTAssertTrue(app.welcomeConnectButton.waitForExistence(timeout: 5))
    }

    func test_welcomeScreen_showsGuestButton() {
        XCTAssertTrue(app.welcomeGuestButton.waitForExistence(timeout: 5))
    }

    // MARK: - Navigation

    func test_tapGuestButton_displaysTabBar() {
        app.navigateAsGuest()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    func test_tapGuestButton_dismissesWelcomeScreen() {
        app.navigateAsGuest()
        // WelcomeView is gone once the tab bar appears
        XCTAssertFalse(app.welcomeGuestButton.exists)
    }
}
