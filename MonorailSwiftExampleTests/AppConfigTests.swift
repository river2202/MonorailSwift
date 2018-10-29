import Quick
import Nimble
@testable import MonorailSwiftExample
@testable import MonorailSwift

class AppConfig_Tests: QuickSpec {
    
    override func spec() {
        describe("Load StackOverflow app from config") {
            it("load client app info from stub/config/stackapp.json") {
                let config = AppConfig()
                
//                let dontCheckInClientAppSecret = "Well this make no sense as MonorailSwift EXMAPLE, all secret is visible in the log file"
                
                
                expect(config.stackAppConfig?.OAuthClientId).to(equal("13405"))
//                expect(config.stackAppConfig?.OAuthClientSecret).to(equal("Stack App Client Secret"), description: dontCheckInClientAppSecret)
//                expect(config.stackAppConfig?.OAuthClientKey).to(equal("Stack App Client Key"), description: dontCheckInClientAppSecret)
//                expect(config.stackAppConfig?.OAuthRedirectUri).to(equal("Stack App OAuth redirectUri"), description: dontCheckInClientAppSecret)
            }
        }
    }
}
