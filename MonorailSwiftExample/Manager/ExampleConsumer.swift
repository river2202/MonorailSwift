import Foundation
import MonorailSwift

class ExampleConsumer {
    static let shared = ExampleConsumer()
    
    func saveToken(token: String?) {
        guard let token = token, let writer = Monorail.shared.writer else {
            return
        }
        
        writer.saveConsumerVariables(key: "token", value: token)
    }
    
    func getToken() -> AccessToken? {
        guard let token = Monorail.shared.reader?.getConsumerVariables(key: "token") as? String else {
            return nil
        }
        
        return AccessToken(expires: 86400, accessToken: token)
    }
}
