//
//  DataTypes.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation
@_implementationOnly import SwiftyJSON

typealias ConversationID = String
typealias MessageID = String
typealias UserID = String

typealias JSONObject = [String: Any]
typealias JSONArray = [JSONObject]

enum Environment {
    case development
    case production

    private static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else { fatalError("Plist file not found") }
        return dict
    }()

    static let current: Environment = {
        guard let configuration = Environment.infoDictionary["Configuration"] as? String else {
            return .production
        }

        if configuration.contains("Development") {
            return .development
        } else if configuration.contains("Production") {
            return .production
        } else {
            return .production
        }
    }()

    var baseAPIURL: URL {
        switch self {
        case .development:
            return URL(string: "https://apis-dev.salesmate.io")!
        case .production:
            return URL(string: "https://apis.salesmate.io")!
        }
    }
}

enum ChatError: Error {
    case unknown
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

    init?(from json: JSON) {
        do {
            let jsonData = try json.rawData()
            let instance = try jsonDecoder.decode(Self.self, from: jsonData)
            self = instance
        } catch {
            print(error)
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

    init(id: IntegerID, firstName: String, lastName: String, imagePath: String? = nil, email: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.imagePath = imagePath
        self.email = email
    }
}
