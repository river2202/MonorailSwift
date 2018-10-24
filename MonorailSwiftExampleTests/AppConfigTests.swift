import Quick
import Nimble
@testable import MonorailSwiftExample
@testable import MonorailSwift

class AppConfig_Tests: QuickSpec {
    
    override func spec() {
        describe("Load StackOverflow app from config") {
            it("load client app info from stub/config/stackapp.json") {
                let config = AppConfig()
                
                let dontCheckInClientAppSecret = "Don't check in real Client app secrets, keep them locally in stackapp.json and add it to gitignore."
                
                
                expect(config.stackAppConfig?.OAuthClientId).to(equal("Stack App Client ID"), description: dontCheckInClientAppSecret)
                expect(config.stackAppConfig?.OAuthClientSecret).to(equal("Stack App Client Secret"), description: dontCheckInClientAppSecret)
                expect(config.stackAppConfig?.OAuthClientKey).to(equal("Stack App Client Key"), description: dontCheckInClientAppSecret)
                expect(config.stackAppConfig?.OAuthRedirectUri).to(equal("Stack App OAuth redirectUri"), description: dontCheckInClientAppSecret)
            }
        }
    }
}
