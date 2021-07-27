//
//  User.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import Foundation

// MARK: - User
struct User: Codable {
    
    let id: IntegerID
    let firstName: String
    let lastName: String
    let profileUrl: String?
    let availabilityMode: String?
    let availabilityStatus: String?
    let lastSeenAt: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case firstName = "firstName"
        case lastName = "lastName"
        case profileUrl = "profileUrl"
        case availabilityMode = "availability_mode"
        case availabilityStatus = "availability_status"
        case lastSeenAt = "last_seen_at"
        case status = "status"
    }
}

// MARK: - Contact
struct Contact: Codable {
    
    let id: IntegerID
    let name: String
    let email: String?
    let owner: Owner?
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case email = "email"
        case owner = "owner"
        case isDeleted = "isDeleted"
    }
}

// MARK: - Owner
struct Owner: Codable {
    
    let id: IntegerID
    let name: String
    let firstName: String
    let lastName: String
    let photo: String?
    let email: String?
    let mobile: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case firstName = "firstName"
        case lastName = "lastName"
        case photo = "photo"
        case email = "email"
        case mobile = "mobile"
    }
}
