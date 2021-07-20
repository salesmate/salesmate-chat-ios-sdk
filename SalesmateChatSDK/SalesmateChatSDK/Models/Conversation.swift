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
        let userID: Int?
    }
    
    struct View {
        let name: String
        let count: String?
    }
    
    enum Status: String, Codable {
        case open = "open"
        case closed = "closed"
        case snoozed = "snoozed"
    }
    
    enum Sort: String {
        case newest = "newest"
        case oldest = "oldest"
        case waiting = "waiting_longest"
        case priority = "priority_first"
    }
    
    struct DisplayOptions {
        var view: View = View(name: "all", count: nil)
        var teammateID: String? = nil
        var status: Status = .open
        var sort: Sort = .newest
          
        init() {}
    }
    
    let id: String
    let uniqueId: String
    var contactId: IntegerID?
    let verifiedId: IntegerID?
    
    var name: String
    let title: String?
    
    let lastModifiedDate: Date
    let lastMessage: LastMessage?
    
    let conversationReadBy: [Int]?
    
    var isPrioritized: Bool
    var status: Status
    
    let ownerTeam: IntegerID?
    let ownerUser: IntegerID?
    
    let waitingSince: String
    var waitingSinceDate: Date? {
        if let date = DateFormatter.fullISO8601NoFraction.date(from: waitingSince) {
            return date
        } else if let date = DateFormatter.fullISO8601.date(from: waitingSince) {
            return date
        }
        return nil
    }
    
    var tags: [String]?
}

extension Conversation: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case uniqueId = "uniqueId"
        case contactId = "contactId"
        case verifiedId = "verifiedId"
        case name = "name"
        case title = "title"
        case lastModifiedDate = "lastModifiedDate"
        case lastMessage = "lastMessageMetadata"
        case waitingSince = "waitingSince"
        case conversationReadBy = "userIdsConversationReadBy"
        case isPrioritized = "isPrioritized"
        case status = "status"
        case ownerTeam = "ownerTeam"
        case ownerUser = "ownerUser"
        case tags = "tags"
    }
}

extension Conversation.LastMessage: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case messageSummary = "messageSummary"
        case messageType = "messageType"
        case userID = "userId"
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

extension Conversation.View: Codable {
    enum CodingKeys: String, CodingKey {
        case name = "name"
        case count = "count"
    }
    
    init(name: String) {
        self.name = name
        self.count = nil
    }
}

struct RecentConversation {
    
    let id: String

    let ownerTeam: IntegerID?
    let ownerUser: IntegerID?
    
    var status: Conversation.Status
    let statusChangedByUser: IntegerID?
    
    let lastModifiedDate: Date
    let lastMessage: Conversation.LastMessage?
}

extension RecentConversation: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"

        case ownerTeam = "owner_team"
        case ownerUser = "owner_user"

        case status = "status"
        case statusChangedByUser = "last_status_changed_by"
        
        case lastModifiedDate = "last_modified_date"
        case lastMessage = "last_message_metadata"
    }
}
