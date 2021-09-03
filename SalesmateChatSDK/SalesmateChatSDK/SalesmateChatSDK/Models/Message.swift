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
        case isBot = "is_bot"
        case isInbound = "is_inbound"
        case conversationName = "conversation_name"
    }

    enum SendStatus {
        case sending
        case sent
        case fail
    }

    let id: String
    let type: MessageType
    var contents: [BlockToSend]
    let isBot: Bool
    let isInbound: Bool
    let conversationName: String

    var fileToUpload: FileToUpload?
    var uploadedFile: UploadedFile?

    let createdDate: Date = Date()
    var status: SendStatus = .sending

    init(type: MessageType, contents: [BlockToSend], conversationName: String, file: FileToUpload? = nil, isBot: Bool = false, isInbound: Bool = true) {
        self.id = UUID.new
        self.type = type
        self.contents = contents
        self.fileToUpload = file
        self.isBot = isBot
        self.isInbound = isInbound
        self.conversationName = conversationName
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
    let isInternalMessage: Bool
    let type: MessageType
    let createdDate: Date
    let isBot: Bool
    let contents: [Block]?
    let userID: IntegerID?
    var deletedDate: Date?

    let contactName: String?
    let contactEmail: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case isInternalMessage = "is_internal_message"
        case type = "message_type"
        case createdDate = "created_date"
        case isBot = "is_bot"
        case contents = "blockData"
        case userID = "user_id"
        case deletedDate = "deleted_date"
        case contactName = "contact_name"
        case contactEmail = "contact_email"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

func == (lhs: Message, rhs: MessageToSend) -> Bool {
    lhs.id == rhs.id
}
