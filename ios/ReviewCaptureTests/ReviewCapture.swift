import XCTest

final class ReviewCapture: XCTestCase {
    @MainActor func testRolePracticeAndPersistence() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 15))
        func capture(_ name: String) {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        capture("01-role-practice-home")
        app.buttons["Settings"].tap()
        let picker = app.buttons["learning-role"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        app.buttons["Pilot"].tap()
        capture("02-learning-role-settings")
        app.buttons["Done"].tap()
        app.buttons["role-practice"].tap()
        app.buttons["lesson-engine"].tap()
        func reveal(_ element: XCUIElement) {
            for _ in 0..<30 {
                if element.exists && element.isHittable { return }
                app.swipeUp()
            }
            XCTAssertTrue(element.isHittable)
        }
        let choice = app.buttons["answer-1-0"]
        reveal(choice)
        let question = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        question.name = "06-pilot-role-question"
        question.lifetime = .keepAlways
        add(question)
        choice.tap()
        let feedback = app.otherElements["feedback-1"]
        // Feedback is also exposed through its visible text for XCTest versions
        // that flatten the SwiftUI container accessibility tree.
        let explanation = app.staticTexts["Saved for review — compare the next turn"]
        reveal(explanation)
        XCTAssertTrue(feedback.exists || explanation.exists)
        let result = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        result.name = "07-answer-explanation"
        result.lifetime = .keepAlways
        add(result)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        picker.tap()
        app.buttons["Controller"].tap()
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        let entry = app.buttons["role-practice"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        XCTAssertTrue(entry.label.contains("Controller"))
        entry.tap()
        app.buttons["lesson-engine"].tap()
        let controllerChoice = app.buttons["answer-1-0"]
        reveal(controllerChoice)
        capture("08-controller-role-question")
        controllerChoice.tap()
        let correct = app.staticTexts["Correct — follows this dialogue"]
        reveal(correct)
        XCTAssertTrue(correct.exists)
    }

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
