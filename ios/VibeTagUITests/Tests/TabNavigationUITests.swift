import XCTest

final class TabNavigationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITests()
        app.navigateAsGuest()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tab bar structure

    func test_tabBar_hasBibliotecaTab() {
        XCTAssertTrue(app.bibliotecaTab.waitForExistence(timeout: 5))
    }

    func test_tabBar_hasEtiquetasTab() {
        XCTAssertTrue(app.etiquetasTab.waitForExistence(timeout: 5))
    }

    func test_tabBar_hasAjustesTab() {
        XCTAssertTrue(app.ajustesTab.waitForExistence(timeout: 5))
    }

    // MARK: - Tab switching

    func test_tapBibliotecaTab_showsHomeTitle() {
        app.bibliotecaTab.tap()
        XCTAssertTrue(app.staticTexts["Mi Biblioteca"].waitForExistence(timeout: 5))
    }

    func test_tapEtiquetasTab_switchesTab() {
        app.etiquetasTab.tap()
        // The Biblioteca tab title should no longer be the active screen heading
        XCTAssertFalse(app.staticTexts["Mi Biblioteca"].exists)
    }

    func test_tapAjustesTab_showsSettingsTitle() {
        app.ajustesTab.tap()
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 5))
    }

    func test_canSwitchBetweenAllTabs() {
        app.etiquetasTab.tap()
        XCTAssertTrue(app.etiquetasTab.isSelected)

        app.ajustesTab.tap()
        XCTAssertTrue(app.ajustesTab.isSelected)

        app.bibliotecaTab.tap()
        XCTAssertTrue(app.bibliotecaTab.isSelected)
    }
}
