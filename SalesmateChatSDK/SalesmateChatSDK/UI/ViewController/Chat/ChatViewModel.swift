//
//  ChatViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import Foundation

class ChatTopViewModel {

    let title: String
    let headerLogoURL: URL?
    let teamIntro: String
    let backgroundColorCode: String
    let backgroundPatternName: String
    let responseTime: String
    let availableuserViewModel: AvailableUsersViewModel?
    let user: User? = nil

    // MARK: - Init
    init(config: Configeration) {
        title = config.workspace?.name ?? ""

        headerLogoURL = URL(string: config.look?.logourl ?? "")
        backgroundColorCode = config.look?.backgroundColor ?? ""
        backgroundPatternName = config.look?.messengerBackground ?? ""

        teamIntro = config.welcome?.teamIntro ?? ""

        responseTime = "We reply \(config.availability?.replyTime ?? "")"

        let attributes: AvailableUsersViewModel.Attributes

        if headerLogoURL == nil {
            attributes = AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2)
        } else {
            attributes = AvailableUsersViewModel.Attributes(spacing: 25, borderWidth: 1, maxNumberUserToShow: 3)
        }

        availableuserViewModel = AvailableUsersViewModel(users: config.users ?? [],
                                                         attributes: attributes)

    }
}

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
