

struct AccessToken: Decodable {
    
    let expires: Int?
    let accessToken: String?
    
    enum CodingKeys: String, CodingKey {
        case expires
        case accessToken = "access_token"
    }
}
