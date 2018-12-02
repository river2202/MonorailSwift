import XCTest

class Springboard {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    
    var generalCell: XCUIElement {
        return settings.tables.staticTexts["General"]
    }
    
    var resetCell: XCUIElement {
        return settings.tables.staticTexts["Reset"]
    }
    
    var resetLocationPrivacyCell: XCUIElement {
        return settings.tables.staticTexts["Reset Location & Privacy"]
    }
  
    func tapSystemBtn(_ btnName: String) {
        let allowBtn = springboard.buttons[btnName]
        if allowBtn.waitForExistence(timeout: 3) {
            allowBtn.tap()
        }
    }
  
}
