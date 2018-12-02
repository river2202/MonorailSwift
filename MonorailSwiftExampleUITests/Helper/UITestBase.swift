
import XCTest

enum UIElement {
  case button(String)
  case label(String)
  case naviBarButton(String)
  case tableCell(String)
  case tableCellText(String)
  case alert(String)
  case alertTextField(String)
  case alertButton(String)
}

extension XCUIApplication{
  func get(_ element: UIElement) -> XCUIElement {
    switch element {
    case .button(let title):
      return buttons[title]
    case .label(let title):
      return scrollViews.otherElements.staticTexts[title]
    case .naviBarButton(let title):
      return navigationBars.firstMatch.buttons[title]
    case .tableCell(let title):
      return tables.cells[title]
    case .tableCellText(let title):
      return tables.cells.staticTexts[title]
    case .alert(let title):
      return alerts[title]
    case .alertTextField(let title):
      return alerts.collectionViews.textFields[title]
    case .alertButton(let title):
      return alerts.buttons[title]
    }
  }
}

class Robot: ScopeFunc {
  
  let app: XCUIApplication
  let name: String
  
  private let baseWait = TimeInterval(3)
  
  init(name: String, _ app: XCUIApplication) {
    self.app = app
    self.name = name
  }
  
  func iSee(_ element: UIElement) {
    if app.get(element).waitForExistence(timeout: baseWait) == false {
      XCTFail("\(name): I can't see \(element).")
    }
  }
  
  func iSee(_ element: UIElement, has text: String) {
    let element = app.get(element)
    if element.waitForExistence(timeout: baseWait) {
      if element.label != text && element.staticTexts[text].waitForExistence(timeout: baseWait) == false {
          XCTFail("\(name): I can't see \(element) has '\(text)'.")
      }
    } else {
      XCTFail("\(name): I can't see \(element).")
    }
  }
  
  func iSeeNo(_ element: UIElement) {
    let element = app.get(element)
    if element.waitForExistence(timeout: baseWait) {
      XCTFail("\(name): \(element) should not be visible.")
    }
  }
  
  func iTap(_ element: UIElement) {
    iSee(element)
    app.get(element).tap()
  }
  
  func iType(text: String, to element: UIElement) {
    app.get(element).typeText(text)
  }
  
  
}

protocol ScopeFunc {}

extension ScopeFunc {
  @inline(__always) func apply(block: (Self) -> ()) -> Self {
    block(self)
    return self
  }
  @inline(__always) func with<R>(block: (Self) -> R) -> R {
    return block(self)
  }
}

class UITestBase: XCTestCase {
  
  let app = XCUIApplication()
  let springboard = Springboard()
  
  override func setUp() {
    super.setUp()
    
    continueAfterFailure = false
    envTestType = uiTestType
    envUiTestName = name
    
    if isMockTest {
      envMonorailFileName = name
    }
    
    app.launch()
  }
  
  var isMockTest: Bool { return uiTestType == .mockUITest }
}

extension UITestBase: AppConfiguration {
  func setEnvValue(key: String, value: String?) {
    app.launchEnvironment[key] = value
  }
  
  func getEnvValue(key: String) -> String? {
    return app.launchEnvironment[key]
  }
}

