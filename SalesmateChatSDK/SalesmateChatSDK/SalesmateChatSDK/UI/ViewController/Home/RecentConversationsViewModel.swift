//
//  RecentConversationsViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 29/07/21.
//

import Foundation

class RecentConversationsViewModel {

    // MARK: - Private Properties
    private let config: Configeration
    private let conversations: [Conversation]

    private(set) var showPowerBy: Bool = false
    private(set) var actionColorCode: String = ""
    private(set) var shouldShowViewAll: Bool = true
    private(set) var conversationViewModels: [ConversationCellViewModel] = []

    var showAllConversations: (() -> Void)?
    var showConversation: ((Conversation) -> Void)?
    var startNewChat: (() -> Void)?

    // MARK: - Init
    init(config: Configeration, conversations: [Conversation]) {
        self.config = config
        self.conversations = conversations

        prepareProperties()
    }

    func didSelectViewAll() {
        showAllConversations?()
    }

    func didSelecctStartNewChat() {
        startNewChat?()
    }

    func didSelecctConversation(at index: Int) {
        let conversation = conversations[index]

        showConversation?(conversation)
    }

    private func prepareProperties() {
        guard let look = config.look else { return }
        guard let workspace = config.workspace else { return }

        showPowerBy = look.showPoweredBy
        actionColorCode = look.actionColor

        shouldShowViewAll = conversations.count > 2

        let conversationToShow = conversations.prefix(2)
        let users: [User?] = conversationToShow.map { cid in config.users?.first(where: { $0.id == cid.lastUserId }) }
        let zip = zip(conversationToShow, users)

        conversationViewModels = zip.map { ConversationCellViewModel(conversation: $0, user: $1, workspace: workspace)}
    }
}
