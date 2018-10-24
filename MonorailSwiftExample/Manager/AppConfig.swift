import Foundation

struct StackAppConfig: Decodable {
    var OAuthClientId: String
    var OAuthRedirectUri: String
    var OAuthState: String
    var OAuthClientSecret: String
    var OAuthClientKey: String
    
    enum CodingKeys: String, CodingKey {
        case OAuthClientId
        case OAuthRedirectUri
        case OAuthState
        case OAuthClientSecret
        case OAuthClientKey
    }
    
}

class AppConfig {
    
    static let shared = AppConfig()
    
    let stackAppConfig: StackAppConfig?
    var soApi: StackOverflowApi
    
    init() {
        
        if let stackAppConfigFile = StubManager.load("config/stackapp.json"),
            let data = try? Data(contentsOf: stackAppConfigFile) {
            self.stackAppConfig = data.decode(StackAppConfig.self)
        } else {
            self.stackAppConfig = nil
        }
            
        soApi = StackOverflowApi(clientId: stackAppConfig?.OAuthClientId, secret: stackAppConfig?.OAuthClientSecret, key: stackAppConfig?.OAuthClientKey, redirectUri: stackAppConfig?.OAuthRedirectUri, state: stackAppConfig?.OAuthState)
    }
}


