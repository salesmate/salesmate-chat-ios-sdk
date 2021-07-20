//
//  WebSocketEventCreation.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

class PayloadMaker: ChatStreamPayloadMaker {
    
    private var cid: Int = 0
    
    private func nextCID() -> Int {
        cid += 1
        return cid
    }
    
    func handshakeObject() -> Data? {
//        guard let authToken = configuration?.csAuthToken else {
//            print("Chat AuthToken not found")
//            return nil
//        }
//
//        let authToken = ""
//        let event: JSONObject = [
//            Payload.Keys.event: Payload.Event.handshake.rawValue,
//            Payload.Keys.data: [
//                Payload.Keys.authToken: authToken
//            ],
//            Payload.Keys.cid: nextCID()
//        ]
//
//        return try? JSONSerialization.data(withJSONObject: event, options: [])
        return nil
    }
    
    func subscribeObjects() -> [Data]? {
//        guard let linkName = configuration?.linkName,
//              let userID = configuration?.userID,
//              let workspaceID = configuration?.workspaceID else {
//            print("ChatConnectionDetail.linkName, ChatConnectionDetail.userID or ChatConnectionDetail.workspaceID is not set.")
//            return nil
//        }
//
//        let event1: JSONObject = [
//            Payload.Keys.event: Payload.Event.subscribe.rawValue,
//            Payload.Keys.data: [
//                Payload.Keys.channel: "link-\(linkName)-\(userID)"
//            ],
//            Payload.Keys.cid: nextCID()
//        ]
//
//        let event2: JSONObject = [
//            Payload.Keys.event: Payload.Event.subscribe.rawValue,
//            Payload.Keys.data: [
//                Payload.Keys.channel: "link-\(linkName)"
//            ],
//            Payload.Keys.cid: nextCID()
//        ]
//        let event3: JSONObject = [
//            Payload.Keys.event: Payload.Event.subscribe.rawValue,
//            Payload.Keys.data: [
//                Payload.Keys.channel: "link-\(linkName)-\(workspaceID)"
//            ],
//            Payload.Keys.cid: nextCID()
//        ]
//
//        return [event1, event2, event3].compactMap {
//            try? JSONSerialization.data(withJSONObject: $0, options: [])
//        }
        return nil
    }
    
    func presenceObject() -> Data? {
        let event: [String: Any?] = [
            Payload.Keys.event: Payload.Event.tenantIsPresent.rawValue,
            Payload.Keys.data: nil
        ]
        
        return try? JSONSerialization.data(withJSONObject: event, options: [])
    }
    
    func typingObject(for conversation: ConversationID, and uniqueID: String) -> Data? {
//        let eventName = Payload.Event.tenantIsTyping.rawValue
//        let userID = configuration?.userID ?? ""
//        let workspaceID = configuration?.workspaceID ?? ""
//        let messageType = MessageType.comment.rawValue
//
//        let event: JSONObject = [
//            Payload.Keys.event: eventName,
//            Payload.Keys.data: [
//                Payload.Keys.ids: [
//                    Payload.Keys.uniqueID: uniqueID
//                ],
//                Payload.Keys.conversationID: conversation,
//                Payload.Keys.userID: userID,
//                Payload.Keys.workspaceID: workspaceID,
//                Payload.Keys.messageType: messageType
//            ]
//        ]
//
//        return try? JSONSerialization.data(withJSONObject: event, options: [])
        return nil
    }
}
