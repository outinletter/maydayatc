import XCTest

final class ReviewCapture: XCTestCase {
    @MainActor func testAppStoreScreenshots() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Filter"].waitForExistence(timeout: 15))
        func capture(_ name: String) {
            Thread.sleep(forTimeInterval: 2)
            let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            image.name = name
            image.lifetime = .keepAlways
            add(image)
        }
        func reveal(_ element: XCUIElement) {
            for _ in 0..<15 {
                if element.exists && element.isHittable { return }
                app.swipeUp()
            }
            XCTAssertTrue(element.isHittable)
        }
        capture("01-video-archive")
        let video = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Fuel emergency. Pilot declares emergency for ")).firstMatch
        XCTAssertTrue(video.waitForExistence(timeout: 5))
        video.tap()
        XCTAssertTrue(app.navigationBars["ATC Archive"].waitForExistence(timeout: 5))
        capture("02-video-learning")
        reveal(app.staticTexts["ATC · CONTROLLER"].firstMatch)
        capture("03-pilot-controller-dialogue")
        reveal(app.staticTexts["Language reflection"].firstMatch)
        app.swipeUp()
        capture("04-language-reflection")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Update content now")).firstMatch.waitForExistence(timeout: 5))
        capture("05-content-updates")
    }
}
