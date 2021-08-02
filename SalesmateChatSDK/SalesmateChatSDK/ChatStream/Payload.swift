//
//  Payload.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 27/03/21.
//

import Foundation
@_implementationOnly import SwiftyJSON

struct Payload {

    enum Keys {
        static let event = "event"
        static let data = "data"
        static let rid = "rid"
        static let cid = "cid"
        static let isAuthenticated = "isAuthenticated"
        static let authToken = "authToken"
        static let ids = "ids"
        static let conversationID = "conversationId"
        static let userID = "userId"
        static let workspaceID = "workspaceId"
        static let messageType = "messageType"
        static let uniqueID = "uniqueId"
        static let verifiedID = "verifiedId"
        static let channel = "channel"
        static let type = "type"
    }

    enum Event: String, Codable {
        case handshake = "#handshake"
        case subscribe = "#subscribe"
        case publish = "#publish"
        case tenantIsTyping = "tenant-user-is-typing"
        case visitorIsTyping = "visitor-is-typing"
        case tenantIsPresent = "tenant-user-presence"
    }

    enum PublishType: String {
        case newMessage = "NEW_MESSAGE"
        case availableStatusUpdate = "USER_AVAILABILITY_STATUS_UPDATED"
        case conversationHasRead = "CONVERSATION_HAS_READ"
        case assign = "CHANGE_ASSIGNEE"
        case conversationStatusUpdate = "CONVERSATION_STATUS_UPDATE"
        case messageDeleted = "MESSAGE_DELETED"
    }

    let event: Event?
    let data: JSON?
    let rid: String?
    let cid: String?

    init(from json: JSON) {
        event = Event(rawValue: json["event"].string ?? "")
        data = json["data"]
        rid = json["rid"].string
        cid = json["cid"].string
    }

    init(event: Event? = nil, data: JSON? = nil, rid: String? = nil, cid: String? = nil) {
        self.event = event
        self.data = data
        self.rid = rid
        self.cid = cid
    }

    var jsonData: Data? {
        let payload: JSONObject = [
            Payload.Keys.event: event?.rawValue ?? "",
            Payload.Keys.data: data?.object ?? "",
            Payload.Keys.cid: cid ?? ""
        ]

        return try? JSONSerialization.data(withJSONObject: payload, options: [])
    }
}
