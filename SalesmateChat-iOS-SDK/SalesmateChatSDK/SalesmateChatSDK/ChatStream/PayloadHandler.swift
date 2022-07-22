//
//  PayloadHandler.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 25/03/21.
//

import Foundation
@_implementationOnly import SwiftyJSON

enum PayloadHandler {

    static func handle(_ payload: Payload) -> ChatEvent? {
        guard let event = payload.event else { return nil }

        switch event {
        case Payload.Event.publish:
            guard let data = payload.data?[Payload.Keys.data] else { return nil }
            let type = Payload.PublishType(rawValue: data[Payload.Keys.type].string ?? "")

            if let type = type {
                let innerData = data[Payload.Keys.data]

                switch type {
                case .newMessage:
                    return handleNewMessage(event: innerData)
                case .availableStatusUpdate:
                    return handleUserAvailabilityStatusUpdate(event: innerData)
                case .conversationHasSeen:
                    return handleConversationHasSeen(event: innerData)
                case .conversationListUpdate:
                    return handleConversationListUpdate(event: innerData)
                case .messageDeleted:
                    return handleDeleteMessage(event: innerData)
                case .contactCreated:
                    return handleContactData(event: innerData)
                case .contactLogin:
                    return handleContactData(event: innerData)
                }
            } else {
                // Typing event
                guard let conversationID = data[Payload.Keys.conversationID].string else { return nil }

                let userID: String? = {
                    let ID = data[Payload.Keys.userID].stringValue
                    return ID.isEmpty ? nil : ID
                }()

                return .typing(conversationID, userID)
            }
        default:
            return nil
        }
    }

    static private func handleNewMessage(event data: JSON) -> ChatEvent? {
        guard let conversationID = data[Payload.Keys.conversationID].string else { return nil }

        return .messageReceived(conversationID, nil)
    }

    static private func handleUserAvailabilityStatusUpdate(event data: JSON) -> ChatEvent? {
        guard let status = data["status"].string else { return nil }
        guard let userIDs = data["userIds"].arrayObject as? [String] else { return nil }

        if status == "available" {
            return .onlineUsers(userIDs.compactMap({ IntegerID($0) }))
        } else if status == "away" {
            return .offlineUsers(userIDs.compactMap({ IntegerID($0) }))
        }

        return nil
    }

    static private func handleConversationHasSeen(event data: JSON) -> ChatEvent? {
        guard let conversationId = data["conversationId"].string else { return nil }
        guard let contactHasSeen = data["userHasSeen"].bool, contactHasSeen else { return nil }

        return .readStatusChange(conversationId)
    }

    static private func handleConversationListUpdate(event data: JSON) -> ChatEvent? {
        guard let conversationId = data["conversationId"].string else { return nil }

        return .conversationUpdated(conversationId)
    }

    static private func handleDeleteMessage(event data: JSON) -> ChatEvent? {
        let message = data["messageData"]

        guard let conversationId = message["conversation_id"].string else { return nil }
        guard let messageId = message["id"].string else { return nil }
        guard let deletedBy = message["deleted_by"].string else { return nil }
        guard let deletedDate = message["deleted_date"].string else { return nil }

        guard let date = deletedDate.dateFromISO8601Format else { return nil }
        guard let userID = IntegerID(deletedBy) else { return nil }

        return .messageDeleted(conversationId, messageId, userID, date)
    }
    
    static private func handleContactData(event data: JSON) -> ChatEvent? {
        var contactId: String = ""
        if let contactIdStr = data["contactId"].string {
            contactId = contactIdStr
        } else if let contactIdInt = data["contactId"].int {
            contactId = "\(contactIdInt)"
        }
        guard let contactEmail = data["email"].string else { return nil }
        guard let contactName = data["name"].string else { return nil }
        let contact = Contact(id: IntegerID(contactId)!, name: contactName, email: contactEmail, owner: nil, isDeleted: false)
        return .contactData(contact)
    }

}
