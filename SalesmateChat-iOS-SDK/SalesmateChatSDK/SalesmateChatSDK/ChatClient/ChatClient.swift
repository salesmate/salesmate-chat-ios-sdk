//
//  ChatClient.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation

var enableLog: Bool = true

protocol ConversationFetcher {
    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void)
    func getDetail(of conversation: ConversationID, completion: @escaping (Result<Conversation, ChatError>) -> Void)
    func downloadTranscript(of ID: ConversationID, completion: @escaping ((Result<String, ChatError>) -> Void))
}

protocol ConversationOperation {
    func updateRating(of ID: ConversationID, to rating: Int, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func updateRemark(of ID: ConversationID, to remark: String, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func readConversation(ID: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?)
    func sendTyping(to ID: ConversationID, as name: String)
}

protocol MessageFetcher {
    func getMessages(of conversation: ConversationID, at page: Page, completion: @escaping (Result<[Message], ChatError>) -> Void)
}

protocol MessageOperation {
    func send(message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, ChatError>) -> Void)
}

protocol FileOperation {
    func upload(file: FileToUpload, completion: @escaping (Result<UploadedFile, ChatError>) -> Void, progress: ((Float) -> Void)?)
}

extension FileOperation {
    func upload(file: FileToUpload, completion: @escaping (Result<UploadedFile, ChatError>) -> Void, progress: ((Float) -> Void)? = nil) {
        self.upload(file: file, completion: completion, progress: progress)
    }
}

protocol ChatDataSource {
    var conversations: Set<Conversation> { get }
    var messages: [ConversationID: Set<Message>] { get }

    func clearConversations()
    func clearMessages()
}

protocol ChatObservation {
    /**
     Register to chat events which you want to observe.
     
     Not all event of `ChatEventToObserve` is supported.
    
     ## Currently Supported event are:
     - `conversationUpdated`
     - `messageesUpdated`
     - `typing`
     
     Other event are for internal use only.
     
     - Parameter observer: The object that want to observer event.
     - Parameter events: List of event to be observed.
     - Parameter conversation: Pass if only event related to perticuler ConversationID need to be observer.
     - Parameter onEvent: Block to be called whe  event happe.
    */
    func register(observer: AnyObject, for events: [ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void)
}

protocol ChatClient: ChatObservation, ConversationFetcher, ConversationOperation, MessageFetcher, MessageOperation, ChatDataSource, FileOperation {
    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void))
    func connect(waitForFullConnection: Bool, completion: @escaping (Result<Void, ChatError>) -> Void)
    func createContact(with email: String, in conversation: ConversationID?, completion: @escaping (Result<Void, ChatError>) -> Void)
    func loginWith(with loginUser: LoginUser, completion: @escaping (Result<String, ChatError>) -> Void)
    func update(with loginUser: LoginUser, completion: @escaping (Result<String, ChatError>) -> Void)
    func sendDeviceToken(with deviceToken: String, deviceId: String, completion: @escaping (Result<Void, ChatError>) -> Void)
}

extension ChatClient {

    func connect(waitForFullConnection: Bool = false, completion: @escaping (Result<Void, ChatError>) -> Void) {
        self.connect(waitForFullConnection: waitForFullConnection, completion: completion)
    }
}
