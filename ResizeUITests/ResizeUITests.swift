import XCTest

final class ResizeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeScreenRendersBrandCopy() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Resize"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Convert and resize photos in a tap."].exists)
        XCTAssertTrue(app.staticTexts["Select images"].exists)
        XCTAssertTrue(app.buttons["Choose Photos"].exists)
    }
}
