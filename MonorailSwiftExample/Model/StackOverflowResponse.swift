
struct StackOverflowResponse<Item: Decodable>: Decodable {
    let items: [Item]?
    let hasMore: Bool?
    let quotaMax, quotaRemaining: Int?
    
    enum CodingKeys: String, CodingKey {
        case items
        case hasMore = "has_more"
        case quotaMax = "quota_max"
        case quotaRemaining = "quota_remaining"
    }
}
