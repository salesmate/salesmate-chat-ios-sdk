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

    // MARK: - Private Properties
    private let conversationID: ConversationID?
    private let config: Configeration
    private let client: ChatClient
    private let page = Page()

    let topbar: TopBarStyle
    let topViewModel: ChatTopViewModel
    let actionColorCode: String

    private(set) var messageViewModels: [MessageViewModel] = []

    var messagesUpdated: (() -> Void)?

    // MARK: - Init
    init(conversationID: ConversationID? = nil, config: Configeration, client: ChatClient) {
        self.conversationID = conversationID
        self.config = config
        self.client = client

        topViewModel = ChatTopViewModel(config: config)

        actionColorCode = config.look?.actionColor ?? ""

        if topViewModel.headerLogoURL == nil {
            topbar = .withoutLogo
        } else {
            topbar = .withLogo
        }

        self.client.clearMessages()
    }

    private func updateMessages() {
        guard let look = config.look else { return }

        let sortedMessage = client.messages.sorted(by: { $0.createdDate < $1.createdDate })

        messageViewModels = sortedMessage.map { MessageViewModel(message: $0, look: look, users: config.users ?? []) }

        OperationQueue.main.addOperation {
            self.messagesUpdated?()
        }
    }
}

extension ChatViewModel {

    func getMessages() {
        guard let ID = conversationID else { return }

        client.getMessages(of: ID, at: page) { result in
            switch result {
            case .success:
                self.updateMessages()
            case .failure:
                break
            }
        }
    }
}
