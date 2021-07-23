//
//  PayloadHandler.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 25/03/21.
//

import Foundation
@_implementationOnly import SwiftyJSON
@_implementationOnly import HTTP

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
                case .conversationHasRead:
                    return handleConversationHasRead(event: innerData)
                case .assign:
                    return handleAssign(event: innerData)
                case .conversationStatusUpdate:
                    return handleConversationStatusUpdate(event: innerData)
                case .messageDeleted:
                    return handleDeleteMessage(event: innerData)
                }
            } else {
                // Typing event
                guard let conversationID = data[Payload.Keys.conversationID].string else { return nil }
                
                let userID: String? = {
                    let ID = data[Payload.Keys.userID].stringValue
                    return ID.isEmpty ? nil : ID
                }()
                
                guard userID == nil else { return nil }
                
                return .typing(conversationID, userID)
            }
        default:
            return nil
        }
    }
    
    static private func handleNewMessage(event data: JSON) -> ChatEvent? {
        guard let conversationID = data[Payload.Keys.conversationID].string else { return nil }
        
        return .messageReceived(conversationID)
    }
    
    static private func handleUserAvailabilityStatusUpdate(event data: JSON) -> ChatEvent? {
        guard let userIDs = data["userIds"].arrayObject as? [String] else { return nil }
        
        return .offlineUsers(userIDs.compactMap({ IntegerID($0) }))
    }
    
    static private func handleConversationHasRead(event data: JSON) -> ChatEvent? {
        guard let conversationId = data["conversationId"].string else { return nil }
        guard let userHasRead = data["userHasRead"].bool, userHasRead else { return nil }

        return .readStatusChange(conversationId)
    }
    
    static private func handleAssign(event data: JSON) -> ChatEvent? {
        guard let assignObject = data.object as? JSONObject else { return nil }
        guard let assign = Assign(from: assignObject) else { return nil }
        
        return .assign(assign)
    }
    
    static private func handleConversationStatusUpdate(event data: JSON) -> ChatEvent? {
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
}

