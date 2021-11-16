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

    enum Bottom {
        case message
        case askContactDetail
        case startNewChat
    }

    // MARK: - Private Properties
    private let chatOf: ChatOf
    private let conversationID: ConversationID
    private let config: Configeration
    private let client: ChatClient

    private var conversation: Conversation?
    private var lastViewModel: MessageViewModel?

    var topbar: TopBarStyle
    var topViewModel: ChatTopViewModel

    let actionColorCode: String
    let isNew: Bool
    let allowAttachment: Bool

    // var isEmailAddressMandatory: Bool { isNew && config.isEmailAddressMandatory() && rows.isEmpty }

    private(set) var rows: [ChatRow] = []
    private(set) var email: EmailAddress?
    private(set) var showStartNewChat: Bool = false
    var bottom: Bottom = .message {
        didSet { runOnMain { self.bottomBarUpdated?(self.bottom) } }
    }

    var messagesUpdated: (() -> Void)?
    var newMessagesUpdated: (() -> Void)?
    var sendingMessagesUpdated: (() -> Void)?
    var topBarUpdated: (() -> Void)?
    var bottomBarUpdated: ((Bottom) -> Void)?
    var typing: ((CirculerUserProfileViewModel) -> Void)?
    var newChatViewModel: ChatViewModel { ChatViewModel(chatOf: .new, config: config, client: client) }

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

        self.showStartNewChat = config.canStartNewConversation

        if let email = config.contact?.email {
            self.email = EmailAddress(rawValue: email)
        }

        prepareTopViewModel()
        prepareBottomOption()
    }

    func getController() -> ChatController {
        ChatController(viewModel: self, config: config, client: client, conversationID: conversationID)
    }

    func update(_ conversation: Conversation) {
        guard conversation.id == conversationID else { return }

        self.conversation = conversation

        updateTopBar()
        prepareBottomOption()

        lastViewModel?.isSeen = conversation.isReadByUser
    }

    func updateRating(to rating: Int) {
        self.conversation?.rating = String(rating)
    }

    func updateUserReadStatus(to isRead: Bool) {
        self.conversation?.isReadByUser = isRead
    }

    func updateRemark(to remark: String) {
        self.conversation?.remark = remark
    }

    func updateTopBar() {
        prepareTopViewModel()
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

    private func prepareBottomOption() {
        let daysInterval: TimeInterval = TimeInterval(config.preventRepliesInDays * 24 * 60 * 60)

        if isNew, config.isContactDetailMandatory() {
            bottom = .askContactDetail
        } else if config.shouldPreventReplies,
           let closedDate = conversation?.closedDate,
           abs(closedDate.timeIntervalSinceNow) > daysInterval {
            bottom = .startNewChat
        } else {
            bottom = .message
        }
    }

    // TODO: Need to optimize for performance. By caching viewmodel objects which don't change.
    private func updateMessageViewModels(for messages: Set<Message>, sendingMessages: Set<MessageToSend>) {
        guard let look = config.look else { return }

        // Sort
        let sortedMessage = messages.sorted(by: { $0.createdDate < $1.createdDate })
        let sortedsendingMessage = sendingMessages.sorted(by: { $0.createdDate < $1.createdDate })

        // Create View Models
        let messageViewModels = sortedMessage.map { message -> ChatContentViewModelType in
            switch message.type {
            case .comment:
                return MessageViewModel(message: message,
                                        look: look,
                                        users: config.users ?? [],
                                        ratings: config.rating ?? [])
            case .emailAsked:
                return AskContactDetailViewModel(message: message, look: look)
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

        lastViewModel = nil

        // Create Rows
        self.rows = allMessageViewModels.compactMap({ viewModel -> ChatRow? in
            if let viewModel = viewModel as? MessageViewModel {
                return .message(viewModel)
            } else if let viewModel = viewModel as? SendingMessageViewModel {
                return .message(viewModel)
            } else if let viewModel = viewModel as? AskContactDetailViewModel{
                return .askEmail(viewModel)
            } else if let viewModel = viewModel as? AskRatingViewModel {
                return .askRating(viewModel)
            }
            return nil
        })

        if let lastViewModel = allMessageViewModels.last as? MessageViewModel, lastViewModel.alignment == .right {
            self.lastViewModel = lastViewModel
            self.lastViewModel?.isSeen = conversation?.isReadByUser
        } else {
            self.lastViewModel = nil
        }
    }
}
