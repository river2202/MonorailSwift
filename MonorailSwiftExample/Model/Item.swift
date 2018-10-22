//
//  Question.swift
//  StkOvFlow_iOSChallenge
//
//  Created by Gina De La Rosa on 7/12/18.
//  Copyright © 2018 Gina De La Rosa. All rights reserved.

import Foundation

struct Item: Decodable {
    let tags: [String]?
    let owner: Owner?
    let isAnswered: Bool?
    let viewCount, answerCount, score, lastActivityDate: Int?
    let creationDate, questionID: Int?
    let link, title: String?
    let acceptedAnswerID, lastEditDate: Int?
    let body: String?
    let favorited: Bool?
    
    enum CodingKeys: String, CodingKey {
        case tags, owner
        case isAnswered = "is_answered"
        case viewCount = "view_count"
        case answerCount = "answer_count"
        case score
        case lastActivityDate = "last_activity_date"
        case creationDate = "creation_date"
        case questionID = "question_id"
        case link, title
        case acceptedAnswerID = "accepted_answer_id"
        case lastEditDate = "last_edit_date"
        case body
        case favorited
    }
}

struct Owner: Decodable {
    let reputation, userID: Int?
    let userType: UserType?
    let acceptRate: Int?
    let profileImage: String?
    let displayName: String?
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case reputation
        case userID = "user_id"
        case userType = "user_type"
        case acceptRate = "accept_rate"
        case profileImage = "profile_image"
        case displayName = "display_name"
        case link
    }
}

enum UserType: String, Decodable {
    case doesNotExist = "does_not_exist"
    case registered = "registered"
}

struct QuestionResponse: Decodable {
    let items: [Item]
    
    enum CodingKeys: String, CodingKey {
        case items
    }
}
