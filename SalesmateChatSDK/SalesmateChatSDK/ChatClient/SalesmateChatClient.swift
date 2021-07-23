//
//  ChatClientAPI.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation
@_implementationOnly import HTTP

protocol ChatAPI: AnyObject {
    func getAssignCount(completion: @escaping (Result<Int, HTTPError>) -> Void)
    func getAuthToken(completion: @escaping (Result<(workspaceID: String, authToken:String), HTTPError>) -> Void)
    func getConversationViews(completion: @escaping (Result<[Conversation.View], HTTPError>) -> Void)
    func getConversations(for option:Conversation.DisplayOptions, at page: Page, completion: @escaping (Result<[Conversation], HTTPError>) -> Void)
    func getRecentConversations(for contactID: String?, or uniqueID: String?, at page: Page, excluding conversation: ConversationID?, completion: @escaping ((Result<[RecentConversation], HTTPError>) -> Void))
    func send(_ message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, HTTPError>) -> Void)
    func getConversation(by ID:ConversationID, completion: @escaping (Result<Conversation, HTTPError>) -> Void)
    func markAsRead(_ ID:ConversationID, completion: @escaping (Result<[IntegerID], HTTPError>) -> Void)
    func getMessages(of conversation:ConversationID, at page: Page, from date: Date?, completion: @escaping (Result<[Message], HTTPError>) -> Void)
    func upload(_ file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping (Result<UploadedFile, HTTPError>) -> Void)
    func changeStatus(of conversation: ConversationID, to newStatus: Conversation.Status, completion: @escaping ((Result<Void, HTTPError>) -> Void))
    func snoozeConversation(conversationID: ConversationID, snoozeUntil: String?, completion: @escaping ((Result<Void, HTTPError>) -> Void))
    func addTagsToConversation(conversationID: ConversationID, tags:[String],completion: @escaping ((Result<Void, HTTPError>) -> Void))
    func assign(conversation: ConversationID, to team: Team?, completion: @escaping ((Result<Void, HTTPError>) -> Void))
    func assign(conversation: ConversationID, to user: Teammate?, completion: @escaping ((Result<Void, HTTPError>) -> Void))
    
    func changePriority(of ID: ConversationID, to isPrioritized: Bool, completion: @escaping ((Result<Message, HTTPError>) -> Void))
    
    func delete(message ID: String, of conversation: ConversationID, completion: @escaping ((Result<Void, HTTPError>) -> Void))
    func associateContactWithConversation(forContactId contactId:String, andConversationUniqueId uniquId:String, completion: @escaping (Result<Void, HTTPError>) -> Void)
    func getVisitorDetail(of ID: String, completion: @escaping ((Result<Visitor, HTTPError>) -> Void))
}

class SalesmateChatClient {
    
    private var chatStream: ChatStream
    private var chatAPI: ChatAPI
    private var relay: ChatEventRelay = ChatEventRelay()
    
    init(chatStream: ChatStream, chatAPI: ChatAPI) {
        self.chatStream = chatStream
        self.chatAPI = chatAPI
        
        prepareEventListener()
    }
    
    var conversations: Set<Conversation> { Conversation.current }
    var messages: Set<Message> { Message.current }
}

extension SalesmateChatClient: ChatClient {
    
    func associateContactWithConversation(forContactId contactId: String, andConversationUniqueId uniquId: String, completion: @escaping (Result<Void, ChatError>) -> Void) {
        chatAPI.associateContactWithConversation(forContactId: contactId, andConversationUniqueId: uniquId) { result in
            switch result {
            case .success():
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }

    func getAssignedConversationsCount(completion: @escaping (Result<Int, ChatError>) -> Void) {        chatAPI.getAssignCount { result in
            switch result {
            case .success(let count):
                completion(.success(count))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
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
        
        if configuration?.csAuthToken == nil {
            getAuthToken { result in
                switch result {
                case .success():
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
    
    func getConversationViews(completion: @escaping (Result<[Conversation.View], ChatError>) -> Void) {
        chatAPI.getConversationViews { result in
            switch result {
            case .success(let views):
                completion(.success(views))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func getRecentConversations(for contactID: String?, or uniqueID: String?, at page: Page, excluding conversation: ConversationID?, completion: @escaping ((Result<[RecentConversation], ChatError>) -> Void)) {
        chatAPI.getRecentConversations(for: contactID, or: uniqueID, at: page, excluding: conversation) { result in
            switch result {
            case .success(let conversations):
                completion(.success(conversations))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func getConversations(_ options: Conversation.DisplayOptions, at page: Page, completion: ((Result<[Conversation], ChatError>) -> Void)?) {
        chatAPI.getConversations(for: options, at: page) { result in
            switch result {
            case .success(let conversations):
                if page.offset == 0 {
                    Conversation.current.removeAll()
                }
                
                Conversation.current.update(conversations)
                self.relay(.conversationUpdated(nil))
                completion?(.success(conversations))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func getDetail(of conversation: ConversationID, completion: @escaping ((Result<Conversation, ChatError>) -> Void)) {
        chatAPI.getConversation(by: conversation) { result in
            switch result {
            case .success(let conversation):
                Conversation.current.update(with: conversation)
                self.relay(.conversationUpdated(conversation.id))
                completion(.success(conversation))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func send(_ message: MessageToSend, to conversation: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?) {
        chatAPI.send(message, to: conversation) { result in
            switch result {
            case .success(_):
                self.getUpdate(for: conversation)
                completion?(.success(()))
            case .failure(let error):
                print(error)
                completion?(.failure(.messageSendingFail(message)))
            }
        }
    }
    
    func sendTyping(for conversation: String, uniqueId: String) {
        chatStream.sendTyping(for: conversation, and: uniqueId)
    }
    
    func markAsRead(_ conversation: ConversationID) {
        chatAPI.markAsRead(conversation) { _ in }
    }
    
    func getMessages(of conversation: ConversationID, at page: Page, completion: ((Result<[Message], ChatError>) -> Void)?) {
        chatAPI.getMessages(of: conversation, at: page, from: nil) { result in
            switch result {
            case .success(let messages):
                Message.current.update(messages)
                self.relay(.messageesUpdated(conversation, messages))
                completion?(.success(messages))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func getLatestMessages(of ID: ConversationID, completion: ((Result<[Message], ChatError>) -> Void)? = nil) {
        // Find last message date of given ConversationID
        let filtered = messages.filter({ $0.conversationID == ID })
        let latest = filtered.reduce(Date(timeIntervalSince1970: 0)) {
            $1.createdDate > $0 ? $1.createdDate : $0
        }
        
        chatAPI.getMessages(of: ID, at: Page(size: 10), from: latest) { result in
            switch result {
            case .success(let messages):
                Message.current.update(messages)
                self.relay(.messageesUpdated(ID, messages))
                completion?(.success(messages))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func upload(_ file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping ((Result<UploadedFile, ChatError>) -> Void)) {
        chatAPI.upload(file, progress: progress) { result in
            switch result {
            case .success(let file):
                completion(.success(file))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func changeStatus(of conversationID: ConversationID, to newStatus: Conversation.Status, completion: ((Result<Void, ChatError>) -> Void)?) {
        chatAPI.changeStatus(of: conversationID, to: newStatus) { result in
            switch result {
            case .success:
                if var conversation = self.conversations.first(where: { $0.id == conversationID }) {
                    conversation.status = newStatus
                    Conversation.current.update(with: conversation)
                    self.relay(.conversationUpdated(conversationID))
                }
                self.getUpdate(for: conversationID)
                completion?(.success(()))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func snoozeConversation(conversationID: ConversationID, snoozeUntil: String?, completion: @escaping ((Result<Void, ChatError>) -> Void)){
        chatAPI.snoozeConversation(conversationID: conversationID, snoozeUntil: snoozeUntil) { result in
            switch result {
            case .success:
                if var conversation = self.conversations.first(where: { $0.id == conversationID }) {
                    conversation.status = .snoozed
                    Conversation.current.update(with: conversation)
                    self.relay(.conversationUpdated(conversationID))
                }
                self.getUpdate(for: conversationID)
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func addTagsToConversation(conversationID: ConversationID, tags:[String],completion: @escaping ((Result<Void, ChatError>) -> Void)){
        chatAPI.addTagsToConversation(conversationID: conversationID, tags: tags) { result in
            switch result {
            case .success:
                if var conversation = self.conversations.first(where: { $0.id == conversationID }) {
                    conversation.tags = tags;
                    Conversation.current.update(with: conversation)
                    self.relay(.conversationUpdated(conversationID))
                }
                self.getUpdate(for: conversationID)
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func delete(message ID: String, of conversationID: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?) {
        chatAPI.delete(message: ID, of: conversationID) { result in
            switch result {
            case .success(let message):
                self.getUpdate(for: conversationID)
                completion?(.success(message))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func register(observer: AnyObject, for events: [ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void) {
        let observation = ChatEventRelay.Observation(observer: observer,
                                           events: events,
                                           conversation: conversation,
                                           onEvent: onEvent)
        relay.add(observation: observation)
    }
    
    func assign(conversation: ConversationID, to team: Team?, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        chatAPI.assign(conversation: conversation, to: team) { result in
            switch result {
            case .success:
                self.getUpdate(for: conversation)
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func assign(conversation: ConversationID, to user: Teammate?, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        chatAPI.assign(conversation: conversation, to: user) { result in
            switch result {
            case .success:
                self.getUpdate(for: conversation)
                completion(.success(()))
            case .failure(let error):
                print(error)
                completion(.failure(.unknown))
            }
        }
    }
    
    func changePriority(of ID: ConversationID, to isPrioritized: Bool, completion: ((Result<Message, ChatError>) -> Void)? = nil) {
        chatAPI.changePriority(of: ID, to: isPrioritized) { result in
            switch result {
            case .success(let message):
                // Update Conversation
                if var conversation = self.conversations.first(where: { $0.id == ID }) {
                    conversation.isPrioritized = isPrioritized
                    Conversation.current.update(with: conversation)
                    self.relay(.conversationUpdated(ID))
                }
                
                //Update Message
                Message.current.update(with: message)
                self.relay(.messageesUpdated(ID, [message]))
                
                completion?(.success(message))
            case .failure(let error):
                print(error)
                completion?(.failure(.unknown))
            }
        }
    }
    
    func getVisitorDetail(of ID: String, completion: @escaping ((Result<Visitor, ChatError>) -> Void)) {
        chatAPI.getVisitorDetail(of: ID) { result in
            switch result {
            case .success(let visitor):
                completion(.success(visitor))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }
    
    func clearConversations() {
        Conversation.current.removeAll()
    }
    
    func clearMessages() {
        Message.current.removeAll()
    }
}

extension SalesmateChatClient {
    
    private func prepareEventListener() {
        let events: [ChatEventToObserve] = [.disconnected, .conversationUpdated, .readStatusChange,
                                            .assign, .messageReceived, .typing, .messageDeleted]
        
        chatStream.register(observer: self, for: events, of: nil) { event in
            switch event {
            case .disconnected:
                self.relay(event)
            case .conversationUpdated(let ID):
                if let ID = ID {
                    self.getConversation(by: ID)
                    self.getLatestMessages(of: ID)
                } else {
                    self.relay(event)
                }
            case .readStatusChange(let ID):
                self.getConversation(by: ID)
            case .assign(let assign):
                self.getConversation(by: assign.conversationId)
                self.getLatestMessages(of: assign.conversationId)
                self.relay(event)
            case .messageReceived(let conversationID):
                self.getConversation(by: conversationID)
                self.getLatestMessages(of: conversationID)
            case .messageDeleted(let conversationID, let messageID, let deletedBy, let deletedDate):
                self.getConversation(by: conversationID)
                
                guard var message = Message.current.first(where: { $0.id == messageID }) else { return }
                
                message.deletedBy = deletedBy
                message.deletedDate = deletedDate
                
                Message.current.update(with: message)
                
                self.relay(.messageesUpdated(conversationID, [message]))
            case .messageesUpdated:
                break
            case .typing:
                self.relay(event)
            case .offlineUsers:
                break
            }
        }
    }
    
    private func getAuthToken(completion: @escaping (Result<Void, ChatError>) -> Void) {
        chatAPI.getAuthToken { (result) in
            switch result {
            case .success((let workspaceID, let authToken)):
                configuration?.workspaceID = workspaceID
                configuration?.csAuthToken = authToken
                completion(.success(()))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func getConversation(by ID: ConversationID) {
        chatAPI.getConversation(by: ID) { result in
            switch result {
            case .success(let conversation):
                Conversation.current.update(with: conversation)
                self.relay(.conversationUpdated(ID))
            case .failure(let error):
                print(error)
            }
        }
    }
    
    /**
     Get updated detail and latest messages of given `ConversationID`.
     
     - Parameter ID: ID of Conversation for which update is require.
     - Parameter force:
        - false: Update will be loaded only if `chatStream` is not ready.
        - true: Update will be loaded without checking `chatStream` status.

     */
    private func getUpdate(for ID: ConversationID, force: Bool = false) {
        guard force || !chatStream.isReady else { return }
        
        getConversation(by: ID)
        getLatestMessages(of: ID)
    }
}
