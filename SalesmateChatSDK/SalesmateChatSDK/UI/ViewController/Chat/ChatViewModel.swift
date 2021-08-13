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

    enum MessageUpdateEvent {
        case pageLoading
        case newMessage
        case sending
    }

    // MARK: - Private Properties
    private let chatOf: ChatOf
    private let conversationID: ConversationID
    private let config: Configeration
    private let client: ChatClient

    private var conversation: Conversation?

    var topbar: TopBarStyle
    var topViewModel: ChatTopViewModel
    let actionColorCode: String
    let isNew: Bool

    private(set) var messageViewModels: [MessageViewModelType] = []

    var messagesUpdated: (() -> Void)?
    var newMessagesUpdated: (() -> Void)?
    var sendingMessagesUpdated: (() -> Void)?
    var topBarUpdated: (() -> Void)?

    // MARK: - Init
    init(chatOf: ChatOf, config: Configeration, client: ChatClient) {
        self.chatOf = chatOf
        self.config = config
        self.client = client
        self.actionColorCode = config.look?.actionColor ?? ""

        switch chatOf {
        case .new:
            conversationID = UUID.new
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
    }

    func getController() -> ChatController {
        ChatController(viewModel: self, client: client, conversationID: conversationID)
    }

    func update(_ conversation: Conversation) {
        guard conversation.id == conversationID else { return }

        self.conversation = conversation
    }

    func update(_ messages: Set<Message>, sendingMessages: Set<MessageToSend>, for event: MessageUpdateEvent) {
        updateMessageViewModels(for: messages, sendingMessages: sendingMessages)

        OperationQueue.main.addOperation {
            switch event {
            case .pageLoading: self.newMessagesUpdated?()
            case .newMessage: self.newMessagesUpdated?()
            case .sending: self.sendingMessagesUpdated?()
            }
        }
    }
}

extension ChatViewModel {

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

    private func updateMessageViewModels(for messages: Set<Message>, sendingMessages: Set<MessageToSend>) {
        guard let look = config.look else { return }

        let sortedMessage = messages.sorted(by: { $0.createdDate < $1.createdDate })
        let sortedsendingMessage = sendingMessages.sorted(by: { $0.createdDate < $1.createdDate })

        let messageViewModels = sortedMessage.map { MessageViewModel(message: $0, look: look, users: config.users ?? []) }
        let sendingViewModels = sortedsendingMessage.map { SendingMessageViewModel(message: $0, look: look, users: config.users ?? []) }

        self.messageViewModels = messageViewModels + sendingViewModels
    }
}
