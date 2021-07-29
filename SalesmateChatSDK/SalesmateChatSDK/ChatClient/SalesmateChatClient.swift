//
//  ChatClientAPI.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

class SalesmateChatClient {
    
    private let config: Configeration
    private let chatStream: ChatStream
    private let chatAPI: ChatAPI
    private let relay: ChatEventRelay = ChatEventRelay()
    
    init(config: Configeration, chatStream: ChatStream, chatAPI: ChatAPI) {
        self.config = config
        self.chatStream = chatStream
        self.chatAPI = chatAPI
        
        prepareEventListener()
    }
    
    var conversations: Set<Conversation> { Conversation.current }
    var messages: Set<Message> { Message.current }
}

extension SalesmateChatClient: ChatClient {
    
    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void)) {
        chatAPI.getConfigerations { result in
            completion(result)
        }
    }
    
    func connect(waitForFullConnection: Bool = false, completion: @escaping (Result<Void, ChatError>) -> Void) {
        
        func whenAuthTokenAvailable() {
            if waitForFullConnection {
                self.chatStream.connect(completion: completion)
            } else {
                self.chatStream.connect(completion: { _ in })
                completion(.success(()))
            }
        }

        if config.socketAuthToken == nil {
            chatAPI.getAuthToken { result in
                switch result {
                case .success((let pseudoName, let authToken, let channels)):
                    self.config.pseudoName = pseudoName
                    self.config.socketAuthToken = authToken
                    self.config.channels = channels
                    
                    whenAuthTokenAvailable()
                case .failure(let error):
                    print(error)
                    completion(.failure(ChatError.unknown))
                }
            }
        } else {
            whenAuthTokenAvailable()
        }
    }
}

extension SalesmateChatClient: ConversationFetcher {
    
    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void) {
        chatAPI.getConversations(at: page) { result in
            completion(result)
        }
    }
}

extension SalesmateChatClient {
    
    private func prepareEventListener() {
//        let events: [ChatEventToObserve] = [.disconnected, .conversationUpdated, .readStatusChange,
//                                            .assign, .messageReceived, .typing, .messageDeleted]
//
//        chatStream.register(observer: self, for: events, of: nil) { event in
//            switch event {
//            case .disconnected:
//                self.relay(event)
//            case .conversationUpdated(let ID):
//                if let ID = ID {
//                    self.getConversation(by: ID)
//                    self.getLatestMessages(of: ID)
//                } else {
//                    self.relay(event)
//                }
//            case .readStatusChange(let ID):
//                self.getConversation(by: ID)
//            case .assign(let assign):
//                self.getConversation(by: assign.conversationId)
//                self.getLatestMessages(of: assign.conversationId)
//                self.relay(event)
//            case .messageReceived(let conversationID):
//                self.getConversation(by: conversationID)
//                self.getLatestMessages(of: conversationID)
//            case .messageDeleted(let conversationID, let messageID, let deletedBy, let deletedDate):
//                self.getConversation(by: conversationID)
//
//                guard var message = Message.current.first(where: { $0.id == messageID }) else { return }
//
//                message.deletedBy = deletedBy
//                message.deletedDate = deletedDate
//
//                Message.current.update(with: message)
//
//                self.relay(.messageesUpdated(conversationID, [message]))
//            case .messageesUpdated:
//                break
//            case .typing:
//                self.relay(event)
//            case .offlineUsers:
//                break
//            }
//        }
    }
    
    /**
     Get updated detail and latest messages of given `ConversationID`.
     
     - Parameter ID: ID of Conversation for which update is require.
     - Parameter force:
        - false: Update will be loaded only if `chatStream` is not ready.
        - true: Update will be loaded without checking `chatStream` status.

     */
    private func getUpdate(for ID: ConversationID, force: Bool = false) {
//        guard force || !chatStream.isReady else { return }
//
//        getConversation(by: ID)
//        getLatestMessages(of: ID)
    }
}
