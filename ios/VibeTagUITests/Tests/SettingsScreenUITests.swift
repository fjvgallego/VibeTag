import XCTest

@MainActor
final class SettingsScreenUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITests()
        app.navigateAsGuest()
        app.ajustesTab.tap()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Screen content

    func test_settingsScreen_showsTitle() {
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 5))
    }

    func test_settingsScreen_showsVersionFooter() {
        XCTAssertTrue(app.staticTexts["VibeTag v1.0.0"].waitForExistence(timeout: 5))
    }

    func test_settingsScreen_showsSignInButton_whenNotAuthenticated() {
        // In guest mode the user is not authenticated — Sign In with Apple button should be present
        XCTAssertTrue(app.buttons["Sign in with Apple"].waitForExistence(timeout: 5))
    }

    func test_settingsScreen_doesNotShowLogoutButton_whenNotAuthenticated() {
        XCTAssertFalse(app.buttons["Cerrar Sesión"].exists)
    }

    func test_settingsScreen_doesNotShowDeleteAccountButton_whenNotAuthenticated() {
        XCTAssertFalse(app.buttons["Eliminar Cuenta"].exists)
    }

    // MARK: - Library & Sync section

    func test_settingsScreen_showsSyncNowButton() {
        XCTAssertTrue(app.buttons["Sincronizar ahora"].waitForExistence(timeout: 5))
    }

    func test_settingsScreen_showsAnalyzeLibraryButton() {
        XCTAssertTrue(app.buttons["Analizar Biblioteca (IA)"].waitForExistence(timeout: 5))
    }

    // MARK: - Apple Music link row

    func test_settingsScreen_showsAppleMusicRow() {
        // When not linked, the row shows "Enlazar Apple Music"
        XCTAssertTrue(app.staticTexts["Enlazar Apple Music"].waitForExistence(timeout: 5))
    }
}
