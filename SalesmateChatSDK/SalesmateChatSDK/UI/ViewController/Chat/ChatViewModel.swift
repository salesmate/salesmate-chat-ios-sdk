//
//  ChatViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 02/08/21.
//

import Foundation

class ChatViewModel {

    // MARK: - Private Properties
    private let config: Configeration
    // private let client: ChatClient

    let title: String
    let backgroundColorCode: String
    let backgroundPatternName: String
    let responseTime: String
    let availableuserViewModel: AvailableUsersViewModel

    let actionColorCode: String

    // MARK: - Init
    init(config: Configeration) {
        self.config = config
        // self.client = client

        title = config.workspace?.name ?? ""

        backgroundColorCode = config.look?.backgroundColor ?? ""
        backgroundPatternName = config.look?.messengerBackground ?? ""
        responseTime = "We reply \(config.availability?.replyTime ?? "")"
        availableuserViewModel = AvailableUsersViewModel(users: config.users ?? [],
                                                         attributes: AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2))

        actionColorCode = config.look?.actionColor ?? ""
    }
}
