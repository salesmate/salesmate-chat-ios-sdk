//
//  NewVisitorViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 28/07/21.
//

import Foundation

class NewVisitorViewModel {

    // MARK: - Private Properties
    private let config: Configeration

    private(set) var responseTime: String = ""
    private(set) var availableuserViewModel = AvailableUsersViewModel(users: [], attributes: AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2))
    private(set) var showStartNewChat: Bool = false
    private(set) var showPowerBy: Bool = false
    private(set) var buttonColorCode: String = ""

    var startNewChat: (() -> Void)?

    // MARK: - Init
    init(config: Configeration) {
        self.config = config

        prepareProperties()
    }

    func didSelecctStartNewChat() {
        startNewChat?()
    }

    private func prepareProperties() {
        guard let availability = config.availability else { return }
        guard let look = config.look else { return }

        responseTime = "The team replies \(availability.replyTime)"
        showPowerBy = look.showPoweredBy
        buttonColorCode = look.actionColor
        showStartNewChat = config.canStartNewConversation

        availableuserViewModel = AvailableUsersViewModel(users: config.users ?? [],
                                                         attributes: AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2))
    }
}
