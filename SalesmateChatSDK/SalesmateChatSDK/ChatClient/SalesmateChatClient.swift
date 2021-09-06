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

    private(set) var conversations: Set<Conversation> = []
    private(set) var messages: [ConversationID: Set<Message>] = [:]
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
}

extension SalesmateChatClient: ConversationFetcher {

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
        let events: [ChatEventToObserve] = [.messageReceived, .typing]

        chatStream.register(observer: self, for: events, of: nil) { event in
            switch event {
            case .messageReceived(let CID, _):
                self.getNewMessages(of: CID)
            case .typing:
                self.relay(event)
            default:
                print("This event(\(event)) is not observed by SalesmateChatClient")
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
}
