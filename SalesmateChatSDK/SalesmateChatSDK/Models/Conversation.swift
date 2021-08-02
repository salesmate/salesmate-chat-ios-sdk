//
//  Conversation.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 25/03/21.
//

import Foundation

struct Conversation {

    static var current: Set<Conversation> = []

    struct LastMessage {
        let id: String?
        let messageSummary: String
        let messageType: MessageType?
        let userID: IntegerID?
    }

    let id: String
    let name: String

    let uniqueId: String
    let contactId: IntegerID?
    let verifiedId: IntegerID?
    let ownerUserId: IntegerID?

    let lastMessageDate: Date
    let lastMessage: LastMessage?

    let isRead: Bool
}

extension Conversation: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case uniqueId = "unique_id"
        case contactId = "contact_id"
        case verifiedId = "verified_id"
        case name = "name"
        case lastMessageDate = "last_message_date"
        case lastMessage = "lastMessageData"
        case isRead = "contact_has_read"
        case ownerUserId = "owner_user"
    }
}

extension Conversation.LastMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageSummary = "message_summary"
        case messageType = "message_type"
        case userID = "user_id"
    }
}

extension Conversation: Hashable {

    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
