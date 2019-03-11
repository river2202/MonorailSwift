
import Foundation
import MonorailSwift
import MonorailSwiftTools

extension AppDelegate: AppConfiguration {
  func setEnvValue(key: String, value: String?) { }
  
  func getEnvValue(key: String) -> String? {
    return ProcessInfo.processInfo.environment[key]
  }
}

extension AppDelegate {
  func setupUITest() {
    if let envTestType = envTestType, let envUiTestName = envUiTestName {
      
      switch envTestType {
      case .mockUITest:
        if let envMonorailFileName = envMonorailFileName, let logFileUrl = StubManager.load("UITest/\(envMonorailFileName).json") {
          Monorail.enableReader(from: logFileUrl)
        }
        
      case .integrationUITest:
        _ = Monorail.writeLog(to: envUiTestName)
      }
    }
  }
  
}


