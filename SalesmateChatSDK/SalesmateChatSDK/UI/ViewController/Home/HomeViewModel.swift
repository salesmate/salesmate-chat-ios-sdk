//
//  HomeViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import Foundation

class HomeViewModel {

    // MARK: - Private Properties
    private let config: Configeration
    private let client: ChatClient

    // MARK: - Properties
    private(set) var backgroundColorCode: String = ""
    private(set) var actionColorCode: String = ""

    private(set) var headerLogoURL: URL?
    private(set) var backgroundPatternName: String = ""

    private(set) var greeting: String = ""
    private(set) var teamIntro: String = ""

    var showNewVisitorView: ((NewVisitorViewModel) -> Void)?
    var showRecentConversationsView: ((RecentConversationsViewModel) -> Void)?

    var showAllConversations: ((ConversationsViewModel) -> Void)?
    var startNewChat: ((ChatViewModel) -> Void)?
    var showConversation: ((ChatViewModel) -> Void)?

    // MARK: - Init
    init(config: Configeration, client: ChatClient) {
        self.config = config
        self.client = client

        prepareTopViewProperties()
    }

    // MARK: - Setup
    private func prepareTopViewProperties() {
        guard let look = config.look else { return }

        backgroundColorCode = look.backgroundColor
        actionColorCode = look.actionColor

        headerLogoURL = URL(string: look.logourl)
        backgroundPatternName = look.messengerBackground

        guard let welcome = config.welcome else { return }

        greeting = welcome.greetingMessage
        teamIntro = welcome.teamIntro
    }

    private func askToShowNewVisitorView() {
        let viewModel = NewVisitorViewModel(config: config)

        viewModel.startNewChat = {
            self.askToStartNewChat()
        }

        OperationQueue.main.addOperation {
            self.showNewVisitorView?(viewModel)
        }
    }

    private func askToShowRecentConversationsView(with conversations: [Conversation]) {
        let viewModel = RecentConversationsViewModel(config: config, conversations: conversations)

        viewModel.showAllConversations = {
            self.askToShowAllConversations()
        }

        viewModel.startNewChat = {
            self.askToStartNewChat()
        }

        viewModel.showConversation = { ID in
            self.askToShowConversation(with: ID)
        }

        OperationQueue.main.addOperation {
            self.showRecentConversationsView?(viewModel)
        }
    }

    private func askToShowAllConversations() {
        let viewModel = ConversationsViewModel(config: self.config, client: self.client)

        OperationQueue.main.addOperation {
            self.showAllConversations?(viewModel)
        }
    }

    private func askToStartNewChat() {
        let viewModel = ChatViewModel(config: config, client: client)

        OperationQueue.main.addOperation {
            self.startNewChat?(viewModel)
        }
    }

    private func askToShowConversation(with ID: ConversationID) {
        let viewModel = ChatViewModel(conversationID: ID, config: config, client: client)

        OperationQueue.main.addOperation {
            self.showConversation?(viewModel)
        }
    }
}

extension HomeViewModel {

    func getRecentConversations() {
        client.getConversations(at: Page(size: 3)) { result in
            switch result {
            case .success(let conversations):
                if conversations.isEmpty {
                    self.askToShowNewVisitorView()
                } else {
                    self.askToShowRecentConversationsView(with: conversations)
                }
            case .failure:
                break
            }
        }
    }
}
