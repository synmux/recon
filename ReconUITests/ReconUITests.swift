import XCTest

final class ReconUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeScreenRendersBrandCopy() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Recon"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Convert and recon photos in a tap."].exists)
        XCTAssertTrue(app.staticTexts["Select images"].exists)
        XCTAssertTrue(app.buttons["Choose Photos"].exists)
    }
}
