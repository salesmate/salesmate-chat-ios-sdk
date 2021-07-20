//
//  ChatClient.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

var enableLog: Bool = true

var configuration: ChatConnectionConfiguration? = nil

var workspaceID: String? { configuration?.workspaceID }

protocol ChatDataSource {
    var conversations: Set<Conversation> { get }
    var messages: Set<Message> { get }
    
    func clearConversations()
    func clearMessages()
}

protocol ConversationFetcher {
    func getConversations(_ options: Conversation.DisplayOptions, at page: Page, completion: ((Result<[Conversation], ChatError>) -> Void)?)
    func getRecentConversations(for contactID: String?, or uniqueID: String?, at page: Page, excluding conversation: ConversationID?, completion: @escaping ((Result<[RecentConversation], ChatError>) -> Void))
    func getDetail(of conversation: ConversationID, completion: @escaping ((Result<Conversation, ChatError>) -> Void))
}

extension ConversationFetcher {
    
    func getConversations(_ options: Conversation.DisplayOptions, at page: Page, completion: ((Result<[Conversation], ChatError>) -> Void)? = nil) {
        self.getConversations(options, at: page, completion: completion)
    }
    
    func getRecentConversations(for contactID: String? = nil, or uniqueID: String? = nil, at page: Page, excluding conversation: ConversationID? = nil, completion: @escaping ((Result<[RecentConversation], ChatError>) -> Void)) {
        self.getRecentConversations(for: contactID, or: uniqueID, at: page, excluding: conversation, completion: completion)
    }
}

protocol ConversationOperation {
    func markAsRead(_ conversation: ConversationID)
    func assign(conversation: ConversationID, to team: Team?, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func assign(conversation: ConversationID, to user: Teammate?, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func sendTyping(for conversation: ConversationID, uniqueId: String)
    func changePriority(of ID: ConversationID, to isPrioritized: Bool, completion: ((Result<Message, ChatError>) -> Void)?)
    func changeStatus(of conversation: ConversationID, to newStatus: Conversation.Status, completion: ((Result<Void, ChatError>) -> Void)?)
    func snoozeConversation(conversationID: ConversationID, snoozeUntil: String?, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func addTagsToConversation(conversationID: ConversationID, tags: [String], completion: @escaping ((Result<Void, ChatError>) -> Void))
}

extension ConversationOperation {
    
    func changeStatus(of conversation: ConversationID, to newStatus: Conversation.Status, completion: ((Result<Void, ChatError>) -> Void)? = nil) {
        self.changeStatus(of: conversation, to: newStatus, completion: completion)
    }
    
    func changePriority(of ID: ConversationID, to isPrioritized: Bool, completion: ((Result<Message, ChatError>) -> Void)? = nil) {
        self.changePriority(of: ID, to: isPrioritized, completion: completion)
    }
}

protocol MessageFetcher {
    func getMessages(of conversation: ConversationID, at page: Page, completion: ((Result<[Message], ChatError>) -> Void)?)
    func getLatestMessages(of ID: ConversationID, completion: ((Result<[Message], ChatError>) -> Void)?)
}

extension MessageFetcher {

    func getMessages(of conversation: ConversationID, at page: Page, completion: ((Result<[Message], ChatError>) -> Void)? = nil) {
        self.getMessages(of: conversation, at: page, completion: completion)
    }
    
    func getLatestMessages(of ID: ConversationID, completion: ((Result<[Message], ChatError>) -> Void)? = nil) {
        self.getLatestMessages(of: ID, completion: completion)
    }
}

protocol MessageOperation {
    func send(_ message: MessageToSend, to conversation: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?)
    func delete(message ID: String, of conversation: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?)
}

extension MessageOperation {
    
    func send(_ message: MessageToSend, to conversation: ConversationID, completion: ((Result<Void, ChatError>) -> Void)? = nil) {
        self.send(message, to: conversation, completion: completion)
    }
    
    func delete(message ID: String, of conversation: ConversationID, completion: ((Result<Void, ChatError>) -> Void)? = nil) {
        self.delete(message: ID, of: conversation, completion: completion)
    }
}

protocol ChatObservation {
    /**
     Register to chat events which you want to observe.
     
     Not all event of `ChatEventToObserve` is supported.
    
     ## Currently Supported event are:
     - `conversationUpdated`
     - `messageesUpdated`
     - `typing`
     - `assign`
     - `disconnected`
     
     Other event are for internal use only.
     
     - Parameter observer: The object that want to observer event.
     - Parameter events: List of event to be observed.
     - Parameter conversation: Pass if only event related to perticuler ConversationID need to be observer.
     - Parameter onEvent: Block to be called whe  event happe.
    */
    func register(observer: AnyObject, for events:[ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void)
}

protocol ChatClient: ChatDataSource, ConversationFetcher, MessageFetcher, ConversationOperation, MessageOperation, ChatObservation {
    func connect(waitForFullConnection: Bool, completion: @escaping (Result<Void, ChatError>) -> Void)
    func getAssignedConversationsCount(completion: @escaping (Result<Int, ChatError>) -> Void)
    func getConversationViews(completion: @escaping (Result<[Conversation.View], ChatError>) -> Void)
    func upload(_ file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping ((Result<UploadedFile, ChatError>) -> Void))
    func associateContactWithConversation(forContactId contactId:String, andConversationUniqueId uniquId:String, completion: @escaping (Result<Void, ChatError>) -> Void)
    func getVisitorDetail(of ID: String, completion: @escaping ((Result<Visitor, ChatError>) -> Void))
}

extension ChatClient {
    
    func connect(waitForFullConnection: Bool = false, completion: @escaping (Result<Void, ChatError>) -> Void) {
        self.connect(waitForFullConnection: waitForFullConnection, completion: completion)
    }
    
    func upload(_ file: FileToUpload, progress: ((Float) -> Void)? = nil, completion: @escaping ((Result<UploadedFile, ChatError>) -> Void)) {
        self.upload(file, progress: progress, completion: completion)
    }
}
