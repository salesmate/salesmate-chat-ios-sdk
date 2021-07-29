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
    
    private(set) var headerLogoURL: URL? = nil
    private(set) var backgroundPatternURL: URL? = nil
    
    private(set) var greeting: String = ""
    private(set) var teamIntro: String = ""
    
    var showNewVisitorView: ((NewVisitorViewModel) -> Void)?
    var showRecentConversationsView: ((RecentConversationsViewModel) -> Void)?
    
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
        backgroundPatternURL = patternURL(for: look.messengerBackground)
        
        guard let welcome = config.welcome else { return }
        
        greeting = welcome.greetingMessage
        teamIntro = welcome.teamIntro
    }
    
    private func patternURL(for name: String) -> URL? {
        let fileName = name.replacingOccurrences(of: "pattern", with: "pt")
        
        return URL(string: "https://\(config.identity.tenantID)/assets/images/pattern/\(fileName).png")
    }
    
    private func askToShowNewVisitorView() {
        let viewModel = NewVisitorViewModel(config: config)
        
        OperationQueue.main.addOperation {
            self.showNewVisitorView?(viewModel)
        }
    }
    
    private func askToShowRecentConversationsView(with conversations: [Conversation]) {
        let viewModel = RecentConversationsViewModel(config: config, conversations: conversations)
        
        OperationQueue.main.addOperation {
            self.showRecentConversationsView?(viewModel)
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
