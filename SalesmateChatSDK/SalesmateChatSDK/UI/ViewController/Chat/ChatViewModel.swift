//
//  ChatViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import Foundation

class ChatViewModel {

    enum TopBarStyle {
        case withoutLogo
        case withLogo
        case assigned
    }

    enum ChatOf {
        case new
        case conversation(Conversation)
        case conversationID(ConversationID)
    }

    private static let pageSize = 50

    // MARK: - Private Properties
    private let chatOf: ChatOf
    private let conversationID: ConversationID
    private let config: Configeration
    private let client: ChatClient

    private var page = Page(size: ChatViewModel.pageSize)
    private var conversation: Conversation?

    var topbar: TopBarStyle
    var topViewModel: ChatTopViewModel
    let actionColorCode: String
    let isNew: Bool
    let pageSize = ChatViewModel.pageSize

    private(set) var messageViewModels: [MessageViewModel] = []

    var messagesUpdated: (() -> Void)?
    var newMessagesUpdated: (() -> Void)?
    var topBarUpdated: (() -> Void)?

    // MARK: - Init
    init(chatOf: ChatOf, config: Configeration, client: ChatClient) {
        self.chatOf = chatOf
        self.config = config
        self.client = client
        self.actionColorCode = config.look?.actionColor ?? ""

        switch chatOf {
        case .new:
            conversationID = UUID().uuidString
            isNew = true
        case .conversation(let conversation):
            conversationID = conversation.id
            self.conversation = conversation
            isNew = false
        case .conversationID(let ID):
            conversationID = ID
            isNew = false
        }

        self.topViewModel = ChatTopViewModel(config: config)
        self.topbar = (topViewModel.headerLogoURL == nil) ? .withoutLogo : .withLogo

        prepareTopViewModel()
        prepareClient()
    }

    private func prepareTopViewModel() {
        if let user = config.users?.first(where: { $0.id == conversation?.lastUserId }) {
            topbar = .assigned
            topViewModel = ChatTopViewModel(config: config, user: user)
        } else {
            self.topViewModel = ChatTopViewModel(config: config)
            self.topbar = (topViewModel.headerLogoURL == nil) ? .withoutLogo : .withLogo
        }

        OperationQueue.main.addOperation {
            self.topBarUpdated?()
        }
    }

    private func prepareClient() {
        client.clearMessages()

        client.register(observer: self, for: [.messageReceived], of: conversationID) { event in
            switch event {
            case .messageReceived(_, let messages):
                guard let messages = messages, !messages.isEmpty else { return }
                self.newMessagesReceived()
            default:
                print("This event(\(event)) is not observed by SalesmateChatClient")
            }
        }
    }

    private func updateMessageViewModels() {
        guard let look = config.look else { return }
        guard let messages = client.messages[conversationID] else { return }

        let sortedMessage = messages.sorted(by: { $0.createdDate < $1.createdDate })

        messageViewModels = sortedMessage.map { MessageViewModel(message: $0, look: look, users: config.users ?? []) }
    }

    private func newMessagesReceived() {
        updateMessageViewModels()

        OperationQueue.main.addOperation {
            self.newMessagesUpdated?()
        }
    }

    private func updateMessages() {
        updateMessageViewModels()

        OperationQueue.main.addOperation {
            self.messagesUpdated?()
        }
    }
}

extension ChatViewModel {

    func startLoadingDetails() {
        client.getDetail(of: conversationID) { result in
            switch result {
            case .success(let detail):
                self.conversation = detail
                self.prepareTopViewModel()
                self.getMessages()
            case .failure:
                break
            }
        }
    }

    func getMessages() {
        client.getMessages(of: conversationID, at: page) { result in
            switch result {
            case .success:
                self.updateMessages()
                self.page.next()
            case .failure:
                break
            }
        }
    }
}
