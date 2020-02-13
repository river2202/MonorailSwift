import Foundation
import SafariServices
import MonorailSwift

typealias SOApi = StackOverflowApi

enum StackOverflowApiError: Error {
    case missingClientAppInfo
    case oauthError
    case accessTokenError
    case missingParameter
    case apiReponseError
    case restApiError
}

extension StackOverflowApiError : LocalizedError {
    public var errorDescription: String? {
        return "\(self)"
    }
    
    func from(_ error: RestApiResourceError?) -> StackOverflowApiError {
        if error != nil {
            return .restApiError
        } else {
            return .apiReponseError
        }
    }
}

typealias StackOverflowApiResult<A> = Result<A, StackOverflowApiError>

class StackOverflowApi {
    
    let clientId: String?
    let secret: String?
    let key: String?
    let redirectUri: String?
    let state: String?
    
    let baseUrl = "https://api.stackexchange.com/2.2/"
    
    var accessToken: AccessToken?
    var authSession: SFAuthenticationSession?

    init(clientId: String?, secret: String?, key: String?, redirectUri: String?, state: String?) {
        self.clientId = clientId
        self.secret = secret
        self.key = key
        self.redirectUri = redirectUri
        self.state = state
    }
    
    func questionDetailApi(questionId: Int?) -> URL? {
        if let questionId = questionId {
            if let accessToken = accessToken?.accessToken, let key = key {
                let urlString = "https://api.stackexchange.com/2.2/questions/\(questionId)?order=desc&sort=activity&site=stackoverflow&key=\(key)&access_token=\(accessToken)&filter=!-*jbN)fQB4uP"
                
                return URL(string: urlString)
            } else {
                return URL(string:"https://api.stackexchange.com/2.2/questions/\(questionId)?order=desc&sort=activity&site=stackoverflow&filter=!9Z(-wwYGT&")
            }
        }
        return nil
    }
    
    func favoriteApi(_ questionId: Int?, _ undo: Bool = false) -> (URL, String)? {
        if let questionId = questionId, let accessToken = accessToken?.accessToken, let key = key {
            
            let urlString = baseUrl + "questions/\(questionId)/favorite" + (undo ? "/undo" : "")
            let queryString = "key=\(key)&access_token=\(accessToken)&site=stackoverflow&filter=!-*jbN)fQB4uP"
            
            return (URL(string: urlString)!, queryString)
        }
        return nil
    }
    
    var myFavoritesApi: URL? {
        if let accessToken = accessToken?.accessToken, let key = key {
            let urlString = "https://api.stackexchange.com/2.2/me/favorites?order=desc&sort=activity&site=stackoverflow&key=\(key)&access_token=\(accessToken)&filter=default"
            return URL(string: urlString)
        } else {
            return URL(string:"https://api.stackexchange.com/2.2/me/favorites?order=desc&sort=activity&site=stackoverflow&filter=default")
        }
    }
}

extension StackOverflowApi {
    
    var isUserLogined: Bool {
        return accessToken != nil
    }
    
    var supportAuth: Bool {
        return clientId != nil && secret != nil && key != nil && redirectUri != nil
    }
    
    func login(completion: @escaping (Error?, AccessToken?) -> Void) {
        
        if let accessToken = ExampleConsumer.shared.getToken() {
            self.accessToken = accessToken
            return completion(nil, accessToken)
        }
        
        guard let clientId = clientId, let secret = secret, let redirectUri = redirectUri else {
            return completion(StackOverflowApiError.missingClientAppInfo, nil)
        }
        
        let state = self.state ?? ""
        
        guard let oauthUrl = URL(string: "https://stackoverflow.com/oauth?client_id=\(clientId)&redirect_uri=\(redirectUri)&scope=private_info,write_access&state=\(state)") else {
            return completion(StackOverflowApiError.missingClientAppInfo, nil)
        }
        
        self.authSession = SFAuthenticationSession(url: oauthUrl, callbackURLScheme: nil, completionHandler: { (callBack: URL?, error: Error? ) in
            guard error == nil else {
                return completion(error, nil)
            }
            
            if let (callbackState, code) = callBack?.retriveStackOverflowOAuthCode(), callbackState == state, let tokenCode = code {
                let resource = RestApiResource<AccessToken>(url: URL(string: "https://stackoverflow.com/oauth/access_token/json")!, formParameters: "client_id=\(clientId)&client_secret=\(secret)&code=\(tokenCode)&redirect_uri=\(redirectUri)")
                URLSession.shared.load(resource, completion: { result in
                    if case .success(let accessToken) = result {
                        self.accessToken = accessToken
                        ExampleConsumer.shared.saveToken(token: accessToken.accessToken)
                        return completion(nil, accessToken)
                    } else {
                        completion(StackOverflowApiError.accessTokenError, nil)
                    }
                })
            } else {
                completion(StackOverflowApiError.oauthError, nil)
            }
        })
        
        self.authSession?.start()
    }
    
    func loadUsername(accessToken: AccessToken, completion: @escaping (Error?, String?) -> Void) {
        
        guard let key = key, let accessTokenString = accessToken.accessToken else {
            return completion(StackOverflowApiError.missingClientAppInfo, nil)
        }
        
        let resource = RestApiResource<UserResponse>(url: URL(string: "https://api.stackexchange.com/2.2/me?key=\(key)&site=stackoverflow&order=desc&sort=reputation&access_token=\(accessTokenString)&filter=default")!)
        URLSession.shared.load(resource, completion: { result in
            if case .success(let userResponse) = result, let userName = userResponse.items?.first?.displayName {
                return completion(nil, userName)
            } else {
                completion(StackOverflowApiError.apiReponseError, nil)
            }
        })
    }
    
    func favorite(_ questionId: Int?, undo: Bool = false, completion: @escaping (StackOverflowApiResult<Question>) -> Void) {
        
        guard let questionId = questionId, let (url, queryString) = favoriteApi(questionId, undo) else {
            return completion(.failure(StackOverflowApiError.missingParameter))
        }
     
        let resource = RestApiResource<QuestionResponse>(url:url, formParameters: queryString)
        URLSession.shared.load(resource, completion: { result in
            if case .success(let questionResponse) = result, let question = questionResponse.items?.first {
                completion(.success(question))
            } else {
                completion(.failure(StackOverflowApiError.apiReponseError))
            }
        })
    }
    
    func myFavorites(completion: @escaping (StackOverflowApiResult<[Question]>) -> Void) {
        
        guard let url = myFavoritesApi else {
            return completion(.failure(StackOverflowApiError.missingParameter))
        }
        
        let resource = RestApiResource<QuestionResponse>(url:url)
        URLSession.shared.load(resource, completion: { result in
            if case .success(let questionResponse) = result, let favorites = questionResponse.items {
                completion(Result.success(favorites))
            } else {
                completion(.failure(StackOverflowApiError.apiReponseError))
            }
            
        })
    }
}

extension URL {
    func retriveStackOverflowOAuthCode() -> (state: String?, code: String?)? {
        if path == "/stackoverflow-login" {
            if let components = URLComponents(url: self, resolvingAgainstBaseURL: false), let queryItems = components.queryItems {
                return (queryItems["state"], queryItems["code"])
            }
        }
        
        return nil
    }
}


extension Array where Element == URLQueryItem {
    subscript(state: String) -> String? {
        get {
            return filter {$0.name == state}.first?.value
        }
    }
}
