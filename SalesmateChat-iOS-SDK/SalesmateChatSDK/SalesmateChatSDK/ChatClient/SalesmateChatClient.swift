//
//  ChatClientAPI.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 23/03/21.
//

import Foundation
import UIKit

let isSalesmateVisitorSDK = "isSalesmateVisitorSDKPush"

class SalesmateChatClient {

    private let config: Configeration
    private let chatStream: ChatStream
    private let chatAPI: ChatAPI
    private let relay: ChatEventRelay = ChatEventRelay()
    private var unreadConversations: [Conversation] = []

    init(config: Configeration, chatStream: ChatStream, chatAPI: ChatAPI) {
        self.config = config
        self.chatStream = chatStream
        self.chatAPI = chatAPI

        prepareEventListener()
    }

    private(set) var conversations: Set<Conversation> = []
    private(set) var messages: [ConversationID: Set<Message>] = [:]

    // For Chat bubble
    private lazy var floatingView : SalesmateChatDragView = {
        var floatingView = SalesmateChatDragView.loadFromNib()
        return floatingView
    }()

}

extension SalesmateChatClient: ChatDataSource {

    func clearConversations() {
        conversations = []
    }

    func clearMessages() {
        messages = [:]
    }
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

        chatAPI.getAuthToken(with: config.socketAuthToken, pseudoName: config.pseudoName) { result in
            switch result {
            case .success((let pseudoName, let authToken, let channels)):
                self.config.pseudoName = pseudoName
                self.config.socketAuthToken = authToken
                self.config.channels = channels
                self.config.saveRequireDataLocally()
                
                /// Get unread conversations
                self.getUnreadConversations()
                
                whenAuthTokenAvailable()
            case .failure(let error):
                print(error)
                completion(.failure(ChatError.unknown))
            }
        }
    }

    func createContact(with email: String, in conversation: ConversationID?, completion: @escaping (Result<Void, ChatError>) -> Void) {
        chatAPI.createContact(with: email, in: conversation, completion: completion)
    }
    
    func loginWith(with loginUser: LoginUser, completion: @escaping (Result<String, ChatError>) -> Void) {
        chatAPI.createLogin(with: loginUser, completion: completion)
    }
        
    func update(with loginUser: LoginUser, completion: @escaping (Result<String, ChatError>) -> Void) {
        chatAPI.createLogin(with: loginUser, completion: completion)
    }
    
    func sendDeviceToken(with deviceToken: String, deviceId: String, completion: @escaping (Result<Void, ChatError>) -> Void) {
        chatAPI.sendDeviceToken(with: deviceToken, deviceId: deviceId, completion: completion)
    }
}

extension SalesmateChatClient: ConversationFetcher {
    
    func getUnreadConversations() {
        if !SalesmateChat.isFromSalesmateChatSDK() {
            
            chatAPI.getUnreadConversations { result in
                switch result {
                case .success(let conversations):
                    self.unreadConversations = conversations
                    self.handleChatHeadBubbleWithLatestConversations(latestConversations: conversations)
                case .failure:
                    break
                }
            }
        }
    }
    

    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void) {
        chatAPI.getConversations(at: page) { result in
            switch result {
            case .success(let conversations):
                self.conversations.update(with: conversations)
                completion(.success(conversations))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getDetail(of conversation: ConversationID, completion: @escaping (Result<Conversation, ChatError>) -> Void) {
        chatAPI.getDetail(of: conversation) { result in
            switch result {
            case .success(let conversation):
                self.conversations.update(with: conversation)
                completion(.success(conversation))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func downloadTranscript(of ID: ConversationID, completion: @escaping ((Result<String, ChatError>) -> Void)) {
        chatAPI.downloadTranscript(of: ID, completion: completion)
    }
}

extension SalesmateChatClient: ConversationOperation {

    func updateRating(of ID: ConversationID, to rating: Int, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        chatAPI.updateRating(of: ID, to: rating, completion: completion)
    }

    func updateRemark(of ID: ConversationID, to remark: String, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        chatAPI.updateRemark(of: ID, to: remark, completion: completion)
    }

    func readConversation(ID: ConversationID, completion: ((Result<Void, ChatError>) -> Void)?) {
        chatAPI.readConversation(ID: ID) { result in
            guard let completion = completion else { return }
            completion(result)
        }
    }

    func sendTyping(to ID: ConversationID, as name: String) {
        chatStream.sendTyping(for: ID, and: name)
    }
}

extension SalesmateChatClient: MessageFetcher {

    func getMessages(of conversation: ConversationID, at page: Page, completion: @escaping (Result<[Message], ChatError>) -> Void) {
        chatAPI.getMessages(of: conversation, at: page) { result in
            switch result {
            case .success(let messages):
                self.update(new: messages, of: conversation)
                completion(.success(messages))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension SalesmateChatClient: MessageOperation {

    func send(message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, ChatError>) -> Void) {
        chatAPI.send(message: message, to: conversation, completion: completion)
    }
}

extension SalesmateChatClient: ChatObservation {

    func register(observer: AnyObject, for events: [ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void) {
        let observation = ChatEventRelay.Observation(observer: observer,
                                                     events: events,
                                                     conversation: conversation,
                                                     onEvent: onEvent)
        relay.add(observation: observation)
    }
}

extension SalesmateChatClient: FileOperation {

    func upload(file: FileToUpload, completion: @escaping (Result<UploadedFile, ChatError>) -> Void, progress: ((Float) -> Void)? = nil) {
        chatAPI.upload(file: file, progress: progress, completion: completion)
    }
}

extension SalesmateChatClient {

    private func prepareEventListener() {
        let events: [ChatEventToObserve] = [.messageReceived, .typing, .conversationUpdated, .readStatusChange, .onlineUsers, .offlineUsers]

        chatStream.register(observer: self, for: events, of: nil) { event in
            switch event {
            case .messageReceived(let CID, _):
                self.getUnreadConversations()
                self.getNewMessages(of: CID)
            case .conversationUpdated(let ID):
                self.updateDetail(of: ID)
            case .readStatusChange(let ID):
                self.updateDetail(of: ID)
            case .onlineUsers, .offlineUsers, .typing:
                self.relay(event)
            default:
                break
            }
        }
    }

    private func updateDetail(of ID: ConversationID) {
        self.getDetail(of: ID) { result in
            switch result {
            case .success(let conversation):
                self.conversations.update(with: conversation)
                self.relay(.conversationUpdated(ID))
            case .failure(let error):
                print(error)
            }
        }
    }

    private func getNewMessages(of conversation: ConversationID) {
        let messages = self.messages[conversation] ?? []
        let lastDate = messages.reduce(Date(timeIntervalSince1970: 0)) { $0 > $1.createdDate ? $0 : $1.createdDate }

        chatAPI.getMessages(of: conversation, from: lastDate) { result in
            switch result {
            case .success(let messages):
                self.update(new: messages, of: conversation)
                self.relay(.messageReceived(conversation, messages))
            case .failure(let error):
                print(error)
            }
        }
    }

    private func update(new messages: [Message], of conversation: ConversationID) {
        var messagesOfConversations = self.messages[conversation] ?? []

        messagesOfConversations.update(with: messages)

        self.messages[conversation] = messagesOfConversations
    }
    
    private func handleChatHeadBubbleWithLatestConversations(latestConversations: [Conversation]) {
        if !SalesmateChat.isFromSalesmateChatSDK() {
            if latestConversations.count > 0 {
                if let latestConversation = latestConversations.first {
                    DispatchQueue.main.async {
                        self.showChatHead(unReadConversation: latestConversation, messageCount: latestConversations.count)
                    }
                }
            }
        }
    }
    
    private func showChatHead(unReadConversation: Conversation, messageCount: Int) {
        
        floatingView.messageCount = messageCount
        
        if unReadConversation.lastMessage?.messageType == .comment {
            var messageStr: String = unReadConversation.lastMessage?.messageSummary ?? ""
            if let blockType = unReadConversation.lastMessage?.blockData?.last?.type {
                switch blockType {
                case .text:
                    messageStr = unReadConversation.lastMessage?.messageSummary ?? ""
                case .image:
                    messageStr = "[Image: \(unReadConversation.lastMessage?.messageSummary ?? "")]"
                case .file:
                    messageStr = unReadConversation.lastMessage?.messageSummary ?? ""
                case .html:
                    messageStr = unReadConversation.lastMessage?.messageSummary ?? ""
                case .orderedList:
                    messageStr = unReadConversation.lastMessage?.messageSummary ?? ""
                case .unorderedList:
                    messageStr = unReadConversation.lastMessage?.messageSummary ?? ""
                }
            }
            floatingView.updateMessageUI(withMessageText: messageStr, withSenderText: unReadConversation.name)
        } else if unReadConversation.lastMessage?.messageType == .ratingAsked {
            floatingView.messageCount = 1
            floatingView.updateMessageUI(withMessageText: "", withSenderText: "Please rate your experience.")
        }
        
        floatingView.showFloatview()
        
        floatingView.clickDragViewBlock = { dragV in
            
            if self.unreadConversations.count == 1 {
                self.floatingView.removeFloatview()
            } else {
                if let removeIndex = self.unreadConversations.firstIndex(where: {$0.id == unReadConversation.id}) {
                    self.unreadConversations.remove(at: removeIndex)
                    self.handleChatHeadBubbleWithLatestConversations(latestConversations: self.unreadConversations)
                }
            }
            SalesmateChat.redirectToConversation(conversation: unReadConversation)
        }
    }
}
