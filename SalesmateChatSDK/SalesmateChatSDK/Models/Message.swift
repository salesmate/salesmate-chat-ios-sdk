//
//  Message.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

enum MessageType: String, Codable {
    case comment
    case note
    case setTitle = "title_set"
    case attachmentsDropped = "attachments_dropped"

    case userNoMore = "user_deleted_or_deactivated"
    case userLicenceRemoved = "chat_licence_removed_of_user"
    case prioritize = "prioritize_set"
    case unprioritize = "prioritize_unset"

    case emailAsked = "email_asked"
    case emailProvided = "email_provided"
    
    case close = "close_conversation"
    case reOpen = "reopen_conversation"
    case sendAndReopen = "send_and_reopen"
    case sendAndClose = "send_and_close"
    case repliedAndClose = "replied_and_close"
    case repliedAndReopen = "replied_and_reopen"
    
    case snoozed = "snoozed"
    case sendAndSnooze = "send_and_snooze"
    
    case assignment
    case assignAndReopen = "assign_and_reopen"
    case repliedAndAssigned = "replied_and_assigned"
    case autoAssignAndReOpen = "auto_assign_and_reopen_on_new_message"
    case unassignedDueToAway = "unassigned_due_to_away"
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
    
    init(type:MessageType, contents: [BlockToSend], referencedUsers: [RefUser]? = nil, referencedTeams: [RefTeam]? = nil, cannedResponseId:String? = nil) {
        self.id = UUID().uuidString.lowercased()
        self.type = type
        self.contents = contents
        self.referencedUsers = referencedUsers
        self.referencedTeams = referencedTeams
        self.cannedResponseId = cannedResponseId;
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
    let summary: String
    let isInternalMessage: Bool
    let type: MessageType
    let createdDate: Date
    let isBot: Bool
    let contents: [Block]?
    let referencedUsers: [RefUser]?
    let referencedTeams: [RefTeam]?
    let userID: IntegerID?
    var deletedBy: IntegerID?
    var deletedDate: Date?
    var snoozedUntil: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case conversationID = "conversation_id"
        case summary = "message_summary"
        case isInternalMessage = "is_internal_message"
        case type = "message_type"
        case createdDate = "created_date"
        case isBot = "is_bot"
        case contents = "blockData"
        case referencedUsers = "referenced_users"
        case referencedTeams = "referenced_teams"
        case userID = "user_id"
        case deletedBy = "deleted_by"
        case deletedDate = "deleted_date"
        case snoozedUntil = "snoozed_until_time"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
