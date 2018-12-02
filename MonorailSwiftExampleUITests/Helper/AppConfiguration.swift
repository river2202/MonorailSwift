
import Foundation

let UI_TEST_TYPE = "UI_TEST_TYPE"
let UI_TEST_NAME = "UI_TEST_NAME"
let UI_TEST_MONORAIL_FILE_NAME = "UI_TEST_MONORAIL_FILE_NAME"

enum TestType: String {
  case mockUITest
  case integrationUITest
}

protocol AppConfiguration: class {
  func setEnvValue(key: String, value: String?)
  func getEnvValue(key: String) -> String?
  
  var envTestType: TestType? { get set }
  var envUiTestName: String? { get set }
  var envMonorailFileName: String? { get set }
}

extension AppConfiguration {
  var envTestType: TestType? {
    get { return TestType(rawValue: getEnvValue(key: UI_TEST_TYPE) ?? "") }
    set { setEnvValue(key: UI_TEST_TYPE, value: newValue?.rawValue) }
  }
  
  var envUiTestName: String? {
    get { return getEnvValue(key: UI_TEST_NAME) }
    set { setEnvValue(key: UI_TEST_NAME, value: newValue) }
  }
  
  var envMonorailFileName: String? {
    get { return getEnvValue(key: UI_TEST_MONORAIL_FILE_NAME) }
    set { setEnvValue(key: UI_TEST_MONORAIL_FILE_NAME, value: newValue) }
  }
}


