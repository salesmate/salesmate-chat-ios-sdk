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

    private let closedDateString: String?
    public var closedDate: Date? {
        guard let closedDateString = closedDateString else { return nil }
        if let date = DateFormatter.fullISO8601NoFraction.date(from: closedDateString) {
            return date
        } else if let date = DateFormatter.fullISO8601.date(from: closedDateString) {
            return date
        } else if let date = DateFormatter.fullISO8601WithoutZ.date(from: closedDateString) {
            return date
        }

        return nil
    }

    let isReadByVisitor: Bool?
    var isReadByUser: Bool?

    var rating: String?
    var remark: String?
}

extension Conversation: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case verifiedId = "verified_id"
        case name
        case lastMessageDate = "last_message_date"
        case lastMessage = "lastMessageData"
        case closedDateString = "closedDate"
        case isReadByVisitor = "contact_has_read"
        case isReadByUser = "userHasSeen"
        case ownerUserId = "owner_user"
        case lastUserId = "last_participating_user_id"
        case rating
        case remark
    }
}

extension Conversation.LastMessage: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case messageSummary = "message_summary"
        case messageType = "message_type"
        case userID = "user_id"
        case blockData = "blockData"
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
