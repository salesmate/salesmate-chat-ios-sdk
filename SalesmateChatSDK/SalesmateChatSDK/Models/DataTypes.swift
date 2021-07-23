//
//  DataTypes.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation
@_implementationOnly import HTTP

typealias ConversationID = String
typealias MessageID = String
typealias UserID = String

enum ChatError: Error {
    case authFail
    case messageSendingFail(MessageToSend)
    case unknown
}

enum ChatEventToObserve {
    case disconnected
    
    case conversationUpdated
    case readStatusChange
    case assign
    
    case messageReceived
    case messageesUpdated
    case messageDeleted
    
    case typing
    
    case offlineUsers
}

enum ChatEvent {
    case disconnected
    
    case conversationUpdated(ConversationID?)
    case readStatusChange(ConversationID)
    case assign(Assign)
    
    case messageReceived(ConversationID)
    case messageDeleted(ConversationID, MessageID, IntegerID, Date)
    case messageesUpdated(ConversationID, [Message])
    
    case typing(ConversationID, UserID?)
    
    case offlineUsers([IntegerID])
        
    func hasAssociatedConversation(ID: ConversationID) -> Bool {
        switch self {
        case .disconnected:
            return false
        case .conversationUpdated(let conversationID):
            if conversationID == ID { return true }
        case .readStatusChange(let conversationID):
            if conversationID == ID { return true }
        case .assign(let assign):
            if assign.conversationId == ID { return true }
        case .messageReceived(let conversationID):
            if conversationID == ID { return true }
        case .messageDeleted(let conversationID, _, _, _):
            if conversationID == ID { return true }
        case .messageesUpdated(let conversationID, _):
            if conversationID == ID { return true }
        case .typing(let conversationID, _):
            if conversationID == ID { return true }
        case .offlineUsers:
            return false
        }
        
        return false
    }
}

func == (lhs: ChatEventToObserve, rhs: ChatEvent) -> Bool {
    switch (lhs, rhs) {
    case (.disconnected, .disconnected): return true
    case (.conversationUpdated, .conversationUpdated): return true
    case (.readStatusChange, .readStatusChange): return true
    case (.assign, .assign): return true
    case (.messageReceived, .messageReceived): return true
    case (.messageesUpdated, .messageesUpdated): return true
    case (.messageDeleted, .messageDeleted): return true
    case (.typing, .typing): return true
    case (.offlineUsers, .offlineUsers): return true
    default: return false
    }
}

class ChatEventRelay {
    
    struct Observation {
        weak var observer: AnyObject?
        let events: [ChatEventToObserve]
        let conversation: ConversationID?
        let onEvent: (ChatEvent) -> Void
    }
    
    private var observations: [Observation] = []
        
    func add(observation: Observation)  {
        remove(observation: observation)
        observations.append(observation)
    }
    
    func remove(observation: Observation)  {
        observations.removeAll(where: { $0.observer === observation.observer })
    }
    
    func callAsFunction(_ event: ChatEvent) {
        relay(event)
    }
    
    func relay(_ event: ChatEvent) {
        for observation in observations {
            guard observation.events.contains(where: { $0 == event }) else { continue }
            
            if let conversationID = observation.conversation {
                guard event.hasAssociatedConversation(ID: conversationID) else { continue }
                observation.onEvent(event)
            } else {
                observation.onEvent(event)
            }
        }
    }
}

private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(DateFormatter.fullISO8601)
    return decoder
}()

extension Decodable {
    
    init?(from json: JSONObject) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let instance = try jsonDecoder.decode(Self.self, from: jsonData)
            self = instance
        } catch {
            print(error)
            return nil
        }
    }
}

extension JSONObject {
    
    func getStringID(for key: String) -> String? {
        if let string = self[key] as? String {
            return string
        } else if let integer = self[key] as? String {
            return String(integer)
        } else {
            return nil
        }
    }
}

struct RefUser: Codable {
    let id: IntegerID
    let name: String
    
    init(id: IntegerID, name: String) {
        self.id = id
        self.name = name
    }
}

struct RefTeam: Codable {
    let id: IntegerID
    let name: String
    
    init(id: IntegerID, name: String) {
        self.id = id
        self.name = name
    }
}

struct Assign: Codable {
    
    enum CodingKeys: String, CodingKey {
        case conversationId
        case userId
        case referencedUsers
        case referencedTeams
        case message = "messageSummary"
    }
    
    let conversationId: ConversationID
    let userId: IntegerID
    let referencedUsers: [RefUser]?
    let referencedTeams: [RefTeam]?
    let message: String
}

struct Team: Codable {
    let id: IntegerID
    let name: String
    
    init(id: IntegerID, name: String) {
        self.id = id
        self.name = name
    }
}

struct Teammate: Codable {
    
    let id: IntegerID
    let firstName: String
    let lastName: String
    let imagePath: String?
    let email: String?
    
    var name: String {
        (firstName + " " + lastName).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var imageURL: URL? {
        guard let imagePath = imagePath else { return nil }
        return URL(string: imagePath)
    }
     
    init(id: IntegerID, firstName: String, lastName: String, imagePath : String? = nil, email: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.imagePath = imagePath
        self.email = email
    }
}
