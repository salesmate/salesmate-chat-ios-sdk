//
//  ChatEventRelay.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 26/07/21.
//

import Foundation

enum ChatEventToObserve {
    case disconnected

    case conversationUpdated
    case readStatusChange
    case assign

    case messageReceived
    case messageDeleted

    case typing

    case offlineUsers
}

func == (lhs: ChatEventToObserve, rhs: ChatEvent) -> Bool {
    switch (lhs, rhs) {
    case (.disconnected, .disconnected): return true
    case (.conversationUpdated, .conversationUpdated): return true
    case (.readStatusChange, .readStatusChange): return true
    case (.messageReceived, .messageReceived): return true
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

    func add(observation: Observation) {
        remove(observation: observation)
        observations.append(observation)
    }

    func remove(observation: Observation) {
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
