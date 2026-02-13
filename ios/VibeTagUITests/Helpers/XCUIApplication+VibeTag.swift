import XCTest

extension XCUIApplication {

    /// Launches the app in a clean UI-test configuration.
    /// Disables animations and Sentry so tests run faster and more reliably.
    func launchForUITests() {
        launchArguments += ["UI_TESTING"]
        launchEnvironment["SENTRY_DISABLED"] = "1"
        launch()
    }

    // MARK: - Welcome screen

    var welcomeConnectButton: XCUIElement {
        buttons["Conectar Apple Music"]
    }

    var welcomeGuestButton: XCUIElement {
        buttons["Enlazar más tarde"]
    }

    // MARK: - Tab bar

    var bibliotecaTab: XCUIElement {
        tabBars.firstMatch.buttons["Biblioteca"]
    }

    var etiquetasTab: XCUIElement {
        tabBars.firstMatch.buttons["Etiquetas"]
    }

    var ajustesTab: XCUIElement {
        tabBars.firstMatch.buttons["Ajustes"]
    }

    // MARK: - Home screen

    var homeSearchField: XCUIElement {
        textFields["Buscar canciones, artistas..."]
    }

    var homeToolbarMenu: XCUIElement {
        buttons["homeToolbarMenu"]
    }

    var homeClearSearchButton: XCUIElement {
        buttons["Limpiar búsqueda"]
    }

    // MARK: - Helpers

    /// Taps "Enlazar más tarde" so all tests start from the main app without
    /// triggering a real MusicKit permission dialog.
    func navigateAsGuest() {
        let guestButton = welcomeGuestButton
        XCTAssertTrue(guestButton.waitForExistence(timeout: 5), "Welcome screen guest button not found")
        guestButton.tap()
    }
}
