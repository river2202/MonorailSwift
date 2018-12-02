import Foundation

struct User: Decodable {
    let reputationChangeQuarter, reputationChangeDay: Int?
    let userType: String?
    let lastAccessDate: Int?
    let link: String?
    let badgeCounts: BadgeCounts?
    let userID: Int?
    let websiteURL: String?
    let isEmployee: Bool?
    let reputationChangeWeek, reputation, reputationChangeMonth, creationDate: Int?
    let location: String?
    let profileImage: String?
    let displayName: String?
    let accountID, reputationChangeYear, lastModifiedDate: Int?
    
    enum CodingKeys: String, CodingKey {
        case reputationChangeQuarter = "reputation_change_quarter"
        case reputationChangeDay = "reputation_change_day"
        case userType = "user_type"
        case lastAccessDate = "last_access_date"
        case link
        case badgeCounts = "badge_counts"
        case userID = "user_id"
        case websiteURL = "website_url"
        case isEmployee = "is_employee"
        case reputationChangeWeek = "reputation_change_week"
        case reputation
        case reputationChangeMonth = "reputation_change_month"
        case creationDate = "creation_date"
        case location
        case profileImage = "profile_image"
        case displayName = "display_name"
        case accountID = "account_id"
        case reputationChangeYear = "reputation_change_year"
        case lastModifiedDate = "last_modified_date"
    }
}

struct BadgeCounts: Codable {
    let bronze, gold, silver: Int?
}

typealias UserResponse = StackOverflowResponse<User>
