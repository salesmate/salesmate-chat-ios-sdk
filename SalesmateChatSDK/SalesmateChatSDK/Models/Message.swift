//
//  Message.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

enum MessageType: String, Codable {
    case comment

    case emailAsked = "email_asked"
    case ratingAsked = "rating_asked"
}

struct MessageToSend: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case type = "message_type"
        case contents = "blocks"
        case referencedUsers = "referenced_users"
        case referencedTeams = "referenced_teams"
        case cannedResponseId = "canned_response_id"
    }

    enum SendStatus {
        case sending
        case sent
        case fail
    }

    let id: String
    let type: MessageType
    let contents: [BlockToSend]
    let referencedUsers: [RefUser]?
    let referencedTeams: [RefTeam]?
    let cannedResponseId: String?
    let createdDate: Date = Date()
    var status: SendStatus = .sending

    init(type: MessageType, contents: [BlockToSend], referencedUsers: [RefUser]? = nil, referencedTeams: [RefTeam]? = nil, cannedResponseId: String? = nil) {
        self.id = UUID().uuidString.lowercased()
        self.type = type
        self.contents = contents
        self.referencedUsers = referencedUsers
        self.referencedTeams = referencedTeams
        self.cannedResponseId = cannedResponseId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MessageToSend, rhs: MessageToSend) -> Bool {
        lhs.id == rhs.id
    }
}

struct Message: Codable, Hashable {

    static var current: Set<Message> = []

    let id: String
    let conversationID: String
    let isInternalMessage: Bool
    let type: MessageType
    let createdDate: Date
    let isBot: Bool
    let contents: [Block]?
    let userID: IntegerID?
    var deletedDate: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case conversationID = "conversation_id"
        case isInternalMessage = "is_internal_message"
        case type = "message_type"
        case createdDate = "created_date"
        case isBot = "is_bot"
        case contents = "blockData"
        case userID = "user_id"
        case deletedDate = "deleted_date"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
