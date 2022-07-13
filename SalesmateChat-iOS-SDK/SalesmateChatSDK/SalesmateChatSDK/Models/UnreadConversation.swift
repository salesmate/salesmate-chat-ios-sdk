//
//  UnreadConversation.swift
//  SalesmateChatSDK
//
//  Created by Vishal Nandoriya on 13/07/22.
//

import Foundation

struct UnreadConversation {

    struct LastMessage {
        let id: String?
        let messageSummary: String
        let messageType: MessageType?
        let userID: IntegerID?
        let blockData: [Block]?
    }

    let id: String
    let name: String

    let contactId: IntegerID?
    let verifiedId: IntegerID?

    let ownerUserId: IntegerID?
    let lastUserId: IntegerID?

    let lastMessageDate: Date
    let lastMessage: LastMessage?

    let isReadByVisitor: Bool?
}

extension UnreadConversation: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case verifiedId = "verified_id"
        case name
        case lastMessageDate = "last_message_date"
        case lastMessage = "lastMessageData"
        case isReadByVisitor = "contact_has_read"
        case ownerUserId = "owner_user"
        case lastUserId = "last_participating_user_id"
    }
}

extension UnreadConversation.LastMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case messageSummary = "message_summary"
        case messageType = "message_type"
        case userID = "user_id"
        case blockData = "blockData"
    }
}

extension UnreadConversation: Hashable {

    static func == (lhs: UnreadConversation, rhs: UnreadConversation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
