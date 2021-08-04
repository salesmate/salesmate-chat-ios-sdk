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
    private let config: Configeration
    // private let client: ChatClient

    let topbar: TopBarStyle
    let topViewModel: ChatTopViewModel
    let actionColorCode: String

    // MARK: - Init
    init(config: Configeration) {
        self.config = config
        // self.client = client

        topViewModel = ChatTopViewModel(config: config)

        actionColorCode = config.look?.actionColor ?? ""

        if topViewModel.headerLogoURL == nil {
            topbar = .withoutLogo
        } else {
            topbar = .withLogo
        }
    }
}
