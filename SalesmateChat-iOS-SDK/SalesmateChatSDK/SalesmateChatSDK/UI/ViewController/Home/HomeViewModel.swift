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
    var recentConversations: [Conversation]?
    
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
        backgroundPatternName = look.messengerBackground.lowercased()

        guard let welcome = config.welcome else { return }

        greeting = welcome.greetingMessage
        teamIntro = welcome.teamIntro
    }

    private func askToShowNewVisitorView() {
        let viewModel = NewVisitorViewModel(config: config)

        viewModel.startNewChat = {
            // Static event for conversation 
            Rapidops.sharedInstance().recordEvent("StartNewConversation", segmentation: ["eventType":"1"]);
            self.askToStartNewChat()
        }

        runOnMain {
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

        viewModel.showConversation = { conversation in
            self.askToShow(conversation: conversation)
        }

        runOnMain {
            self.showRecentConversationsView?(viewModel)
        }
    }

    private func askToShowAllConversations() {
        let viewModel = ConversationsViewModel(config: self.config, client: self.client)

        viewModel.startNewChat = {
            self.askToStartNewChat()
        }
        
        runOnMain {
            self.showAllConversations?(viewModel)
        }
    }

    private func askToStartNewChat() {
        let viewModel = ChatViewModel(chatOf: .new, config: config, client: client)

        runOnMain {
            self.startNewChat?(viewModel)
        }
    }

    private func askToShow(conversation: Conversation) {
        let viewModel = ChatViewModel(chatOf: .conversation(conversation), config: config, client: client)

        runOnMain {
            self.showConversation?(viewModel)
        }
    }

    private func startObservingConversations() {
        client.register(observer: self, for: [.conversationUpdated], of: nil) { event in
            switch event {
            case .conversationUpdated:
                self.getRecentConversations()
            default:
                break
            }
        }
    }
}

extension HomeViewModel {

    func getRecentConversations() {
        client.getConversations(at: Page(size: 3)) { result in
            switch result {
            case .success(let conversations):
                self.recentConversations = conversations
                if conversations.isEmpty {
                    self.askToShowNewVisitorView()
                } else {
                    self.askToShowRecentConversationsView(with: conversations)
                }
                self.startObservingConversations()
            case .failure:
                break
            }
        }
    }
    
    func redirectToConversation(conversationId: String) {
        
        let viewModel = ChatViewModel(chatOf: .conversationID(conversationId), config: config, client: client)

        runOnMain {
            self.showConversation?(viewModel)
        }

        /*if let indexOfConversation = self.recentConversations?.firstIndex(where: {$0.id == conversationId}) {
            if recentConversations != nil {
                let viewModel = ChatViewModel(chatOf: .conversationID(conversationId), config: config, client: client)

                runOnMain {
                    self.showConversation?(viewModel)
                }
            }
        }*/
    }
}
