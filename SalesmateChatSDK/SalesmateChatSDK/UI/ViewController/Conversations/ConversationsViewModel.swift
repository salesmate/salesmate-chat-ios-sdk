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

    private func prepareCellViewModels() {
        let users: [User?] = conversations.map { cid in config.users?.first(where: { $0.id == cid.ownerUserId }) }
        let zip = zip(conversations, users)

        conversationViewModels = zip.map { ConversationCellViewModel(conversation: $0, user: $1)}
    }
}

extension ConversationsViewModel {

    func getRecentConversations() {
        client.getConversations(at: Page(size: 10)) { result in
            switch result {
            case .success(let conversations):
                self.conversations = conversations

                OperationQueue.main.addOperation {
                    self.conversationsUpdated?()
                }
            case .failure:
                break
            }
        }
    }
}
