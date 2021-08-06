//
//  ConversationsViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 30/07/21.
//

import Foundation

class ConversationsViewModel {

    // MARK: - Private Properties
    private let config: Configeration
    private let client: ChatClient

    private var conversations: [Conversation] = [] {
        didSet { prepareCellViewModels() }
    }

    private(set) var backgroundColorCode: String = ""
    private(set) var backgroundPatternName: String = ""

    private(set) var actionColorCode: String = ""
    private(set) var conversationViewModels: [ConversationCellViewModel] = []

    var conversationsUpdated: (() -> Void)?

    // MARK: - Init
    init(config: Configeration, client: ChatClient) {
        self.config = config
        self.client = client

        prepareProperties()
    }

    private func prepareProperties() {
        guard let look = config.look else { return }

        backgroundColorCode = look.backgroundColor
        backgroundPatternName = look.messengerBackground

        actionColorCode = look.actionColor
    }

    private func updateConversations() {
        conversations = Array(self.client.conversations)
        conversations.sort(by: { $0.lastMessageDate > $1.lastMessageDate })

        OperationQueue.main.addOperation {
            self.conversationsUpdated?()
        }
    }

    private func prepareCellViewModels() {
        guard let workspace = config.workspace else { return }

        let users: [User?] = conversations.map { cid in config.users?.first(where: { $0.id == cid.lastUserId }) }
        let zip = zip(conversations, users)

        conversationViewModels = zip.map { ConversationCellViewModel(conversation: $0, user: $1, workspace: workspace)}
    }
}

extension ConversationsViewModel {

    func chatViewModelForConversation(at index: Int) -> ChatViewModel {
        let conversation = conversations[index]

        return ChatViewModel(chatOf: .conversation(conversation), config: config, client: client)
    }

    func getRecentConversations() {

        client.getConversations(at: Page(size: 10)) { result in
            switch result {
            case .success:
                self.updateConversations()
            case .failure:
                break
            }
        }
    }
}
