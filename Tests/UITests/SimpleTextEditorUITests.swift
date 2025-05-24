import XCTest

class SimpleTextEditorUITests: XCTestCase {
    func testOpenFindBar() {
        let app = XCUIApplication()
        app.launch()
        app.menuBars.menuItems["Find..."].click()
        XCTAssertTrue(app.windows.textViews["Find"].exists)
    }
}