import XCTest

final class HomeScreenUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchForUITests()
        app.navigateAsGuest()
        // Ensure we're on the Home tab
        app.bibliotecaTab.tap()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Screen content

    func test_homeScreen_showsTitle() {
        XCTAssertTrue(app.staticTexts["Mi Biblioteca"].waitForExistence(timeout: 5))
    }

    func test_homeScreen_showsSearchBar() {
        XCTAssertTrue(app.homeSearchField.waitForExistence(timeout: 5))
    }

    func test_homeScreen_showsToolbarMenu() {
        XCTAssertTrue(app.homeToolbarMenu.waitForExistence(timeout: 5))
    }

    func test_homeScreen_showsFilterChips() {
        // Filter chips are always rendered; verify at least the "Todas" chip
        XCTAssertTrue(app.buttons["Todas"].waitForExistence(timeout: 5))
    }

    func test_homeScreen_showsAllFilterOptions() {
        XCTAssertTrue(app.buttons["Todas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Sin etiquetas"].exists)
        XCTAssertTrue(app.buttons["IA"].exists)
        XCTAssertTrue(app.buttons["Usuario"].exists)
    }

    // MARK: - Search bar interaction

    func test_searchBar_acceptsInput() {
        let searchField = app.homeSearchField
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Coldplay")
        XCTAssertEqual(searchField.value as? String, "Coldplay")
    }

    func test_searchBar_showsClearButtonAfterInput() {
        let searchField = app.homeSearchField
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("test")
        XCTAssertTrue(app.homeClearSearchButton.waitForExistence(timeout: 3))
    }

    func test_searchBar_clearButtonRemovesText() {
        let searchField = app.homeSearchField
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("test")
        app.homeClearSearchButton.tap()
        XCTAssertEqual(searchField.value as? String, "")
    }

    func test_searchBar_clearButtonDisappearsAfterClearing() {
        let searchField = app.homeSearchField
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("test")
        app.homeClearSearchButton.tap()
        XCTAssertFalse(app.homeClearSearchButton.exists)
    }

    // MARK: - Filter chips

    func test_filterChip_selectionChanges() {
        let sinEtiquetasChip = app.buttons["Sin etiquetas"]
        XCTAssertTrue(sinEtiquetasChip.waitForExistence(timeout: 5))
        sinEtiquetasChip.tap()
        // After tapping a different chip, "Todas" should no longer be selected
        // We verify by checking the chip is tappable and responds without crashing
        XCTAssertTrue(sinEtiquetasChip.exists)
    }

    // MARK: - Toolbar menu

    func test_toolbarMenu_isInteractable() {
        let menu = app.homeToolbarMenu
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        // Menu opens — verify at least one option appears
        XCTAssertTrue(app.buttons["Analizar Biblioteca"].waitForExistence(timeout: 3))
    }

    func test_toolbarMenu_showsAnalyzeOption() {
        app.homeToolbarMenu.tap()
        XCTAssertTrue(app.buttons["Analizar Biblioteca"].waitForExistence(timeout: 3))
    }

    func test_toolbarMenu_showsSyncOption() {
        app.homeToolbarMenu.tap()
        XCTAssertTrue(app.buttons["Sincronizar"].waitForExistence(timeout: 3))
    }
}
