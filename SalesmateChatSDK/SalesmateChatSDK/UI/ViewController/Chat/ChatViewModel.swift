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
    let allowAttachment: Bool

    var isEmailAddressMandatory: Bool { isNew && config.isEmailAddressMandatory() && messageViewModels.isEmpty }

    private(set) var messageViewModels: [MessageViewModelType] = []

    var messagesUpdated: (() -> Void)?
    var newMessagesUpdated: (() -> Void)?
    var sendingMessagesUpdated: (() -> Void)?
    var topBarUpdated: (() -> Void)?
    var typing: ((CirculerUserProfileViewModel) -> Void)?

    // MARK: - Init
    init(chatOf: ChatOf, config: Configeration, client: ChatClient) {
        self.chatOf = chatOf
        self.config = config
        self.client = client
        self.actionColorCode = config.look?.actionColor ?? ""
        self.allowAttachment = config.security?.canUploadAttachment ?? false

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
        ChatController(viewModel: self, config: config, client: client, conversationID: conversationID)
    }

    func update(_ conversation: Conversation) {
        guard conversation.id == conversationID else { return }

        self.conversation = conversation
    }

    func update(_ messages: Set<Message>, sendingMessages: Set<MessageToSend>, for event: MessageUpdateEvent) {
        updateMessageViewModels(for: messages, sendingMessages: sendingMessages)

        runOnMain {
            switch event {
            case .pageLoading: self.messagesUpdated?()
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

        runOnMain {
            self.topBarUpdated?()
        }
    }

    private func updateMessageViewModels(for messages: Set<Message>, sendingMessages: Set<MessageToSend>) {
        guard let look = config.look else { return }

        let sortedMessage = messages.sorted(by: { $0.createdDate < $1.createdDate })
        var sortedsendingMessage = sendingMessages.sorted(by: { $0.createdDate < $1.createdDate })

        let sendingMessageIDs = sortedsendingMessage.map { $0.id }
        let commonIDs = sortedMessage.filter { sendingMessageIDs.contains($0.id)}.map { $0.id }
        sortedsendingMessage.removeAll(where: { commonIDs.contains($0.id) })

        let messageViewModels = sortedMessage.map { MessageViewModel(message: $0, look: look, users: config.users ?? [], ratings: config.rating ?? []) }
        let sendingViewModels = sortedsendingMessage.map { SendingMessageViewModel(message: $0, look: look, users: config.users ?? []) }

        self.messageViewModels = messageViewModels + sendingViewModels
    }
}
