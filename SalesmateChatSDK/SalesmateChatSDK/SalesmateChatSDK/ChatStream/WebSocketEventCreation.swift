//
//  WebSocketEventCreation.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

protocol ChatStreamPayloadMaker {
    func handshakeObject() -> Data?
    func subscribeObjects() -> [Data]?
    func presenceObject() -> Data?
    func typingObject(for conversation: ConversationID, and uniqueID: String) -> Data?
}

class PayloadMaker: ChatStreamPayloadMaker {

    private let config: Configeration
    private var cid: Int = 0

    init(config: Configeration) {
        self.config = config
    }

    private func nextCID() -> Int {
        cid += 1
        return cid
    }

    func handshakeObject() -> Data? {
        guard let authToken = config.socketAuthToken else {
            print("Chat AuthToken not found")
            return nil
        }

        let event: JSONObject = [
            Payload.Keys.event: Payload.Event.handshake.rawValue,
            Payload.Keys.data: [
                Payload.Keys.authToken: authToken
            ],
            Payload.Keys.cid: nextCID()
        ]

        return try? JSONSerialization.data(withJSONObject: event, options: [])
    }

    func subscribeObjects() -> [Data]? {
        let events = config.channels?.map { channel in
            return [
                Payload.Keys.event: Payload.Event.subscribe.rawValue,
                Payload.Keys.data: [
                    Payload.Keys.channel: channel
                ],
                Payload.Keys.cid: nextCID()
            ]
        }

        return events?.compactMap {
            try? JSONSerialization.data(withJSONObject: $0, options: [])
        }
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