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
    private(set) var showPowerBy: Bool = false
    private(set) var buttonColorCode: String = ""

    // MARK: - Init
    init(config: Configeration) {
        self.config = config

        prepareProperties()
    }

    private func prepareProperties() {
        guard let availability = config.availability else { return }
        guard let look = config.look else { return }

        responseTime = "The team typically replies \(availability.replyTime)"
        showPowerBy = look.showPoweredBy
        buttonColorCode = look.actionColor

        availableuserViewModel = AvailableUsersViewModel(users: config.users ?? [],
                                                         attributes: AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2))
    }
}
