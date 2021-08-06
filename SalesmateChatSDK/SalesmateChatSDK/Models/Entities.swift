//
//  User.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import Foundation

// MARK: - User
struct User: Codable {

    enum Status: String, Codable {
        case available
        case away
    }

    let id: IntegerID
    let firstName: String
    let lastName: String
    let profileUrl: String?
    let status: Status?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case profileUrl
        case status
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
        case id
        case name
        case email
        case owner
        case isDeleted
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
        case id
        case name
        case firstName
        case lastName
        case photo
        case email
        case mobile
    }
}
