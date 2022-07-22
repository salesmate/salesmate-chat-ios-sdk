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

enum ChatError: Error {
    case unknown
}

enum ChatEvent {
    case disconnected

    case conversationUpdated(ConversationID)
    case readStatusChange(ConversationID)

    case messageReceived(ConversationID, [Message]?)
    case messageDeleted(ConversationID, MessageID, IntegerID, Date)

    case typing(ConversationID, UserID?)

    case onlineUsers([IntegerID])
    case offlineUsers([IntegerID])
    case contactData(Contact)

    func hasAssociatedConversation(ID: ConversationID) -> Bool {
        switch self {
        case .disconnected:
            return true
        case .conversationUpdated(let conversationID):
            if conversationID == ID { return true }
        case .readStatusChange(let conversationID):
            if conversationID == ID { return true }
        case .messageReceived(let conversationID, _):
            if conversationID == ID { return true }
        case .messageDeleted(let conversationID, _, _, _):
            if conversationID == ID { return true }
        case .typing(let conversationID, _):
            if conversationID == ID { return true }
        case .onlineUsers, .offlineUsers, .contactData:
            return true
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

struct EmailAddress: RawRepresentable, Codable {

    let rawValue: String

    init?(rawValue: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(rawValue.startIndex..<rawValue.endIndex, in: rawValue)
        let matches = detector?.matches(in: rawValue, options: [], range: range)

        guard let match = matches?.first, matches?.count == 1 else { return nil }
        guard match.url?.scheme == "mailto", match.range == range else { return nil }

        self.rawValue = rawValue
    }
}

enum ImageSource {
    case url(URL)
    case local(String)
}
