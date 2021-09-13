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

    var isEmailAddressMandatory: Bool { isNew && config.isEmailAddressMandatory() && rows.isEmpty }

    private(set) var rows: [ChatRow] = []
    private(set) var email: EmailAddress?

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

        if let email = config.contact?.email {
            self.email = EmailAddress(rawValue: email)
        }

        prepareTopViewModel()
    }

    func getController() -> ChatController {
        ChatController(viewModel: self, config: config, client: client, conversationID: conversationID)
    }

    func update(_ conversation: Conversation) {
        guard conversation.id == conversationID else { return }

        self.conversation = conversation
    }

    func updateRating(to rating: Int) {
        self.conversation?.rating = String(rating)
    }

    func updateRemark(to remark: String) {
        self.conversation?.remark = remark
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

    // TODO: Need to optimize for performance. By caching viewmodel objects which don't change.
    private func updateMessageViewModels(for messages: Set<Message>, sendingMessages: Set<MessageToSend>) {
        guard let look = config.look else { return }

        // Sort
        let sortedMessage = messages.sorted(by: { $0.createdDate < $1.createdDate })
        var sortedsendingMessage = sendingMessages.sorted(by: { $0.createdDate < $1.createdDate })

        // Remove duplicate from sending messages
        let sendingMessageIDs = sortedsendingMessage.map { $0.id }
        let commonIDs = sortedMessage.filter { sendingMessageIDs.contains($0.id)}.map { $0.id }
        sortedsendingMessage.removeAll(where: { commonIDs.contains($0.id) })

        // Create View Models
        let messageViewModels = sortedMessage.map { message -> ChatContentViewModelType in
            switch message.type {
            case .comment:
                return MessageViewModel(message: message,
                                        look: look,
                                        users: config.users ?? [],
                                        ratings: config.rating ?? [])
            case .emailAsked:
                return AskEmailViewModel(message: message, look: look)
            case .ratingAsked:
                let ratingConfig = config.rating ?? []
                return AskRatingViewModel(config: ratingConfig,
                                          look: look,
                                          rating: conversation?.rating,
                                          remark: conversation?.remark)
            }
        }

        let sendingViewModels = sortedsendingMessage.map { SendingMessageViewModel(message: $0, look: look, users: config.users ?? []) }
        let allMessageViewModels: [ChatContentViewModelType] = messageViewModels + sendingViewModels

        // Create Rows
        self.rows = allMessageViewModels.compactMap({ viewModel -> ChatRow? in
            if let viewModel = viewModel as? MessageViewModel {
                return .message(viewModel)
            } else if let viewModel = viewModel as? AskEmailViewModel {
                return .askEmail(viewModel)
            } else if let viewModel = viewModel as? AskRatingViewModel {
                return .askRating(viewModel)
            }
            return nil
        })
    }
}
