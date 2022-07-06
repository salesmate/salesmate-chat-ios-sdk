//
//  ChatTopViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
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
    let profileViewModel: CirculerUserProfileViewModel?

    let isUserAvailable: Bool?

    // MARK: - Init
    init(config: Configeration, user: User? = nil) {
        headerLogoURL = URL(string: config.look?.logourl ?? "")
        backgroundColorCode = config.look?.backgroundColor ?? ""
        backgroundPatternName = config.look?.messengerBackground.lowercased() ?? ""

        teamIntro = config.welcome?.teamIntro ?? ""

        if let teamAvailability = config.teamNextAvailableTime {
            if teamAvailability.isPastTime {
                responseTime = "We reply \(config.availability?.replyTime ?? "")"
            } else {
                if let teamAvailabilityText = teamAvailability.fromNow {
                    responseTime = teamAvailabilityText
                } else {
                    responseTime = "We reply \(config.availability?.replyTime ?? "")"
                }
            }
        } else {
            responseTime = "We reply \(config.availability?.replyTime ?? "")"
        }
        
        let attributes: AvailableUsersViewModel.Attributes

        if headerLogoURL == nil {
            attributes = AvailableUsersViewModel.Attributes(spacing: -10, borderWidth: 1, maxNumberUserToShow: 2)
        } else {
            attributes = AvailableUsersViewModel.Attributes(spacing: 25, borderWidth: 1, maxNumberUserToShow: 3)
        }

        availableuserViewModel = AvailableUsersViewModel(users: config.users ?? [],
                                                         attributes: attributes)

        if let user = user {
            title = user.firstName + " " + user.lastName
            profileViewModel = CirculerUserProfileViewModel(user: user, borderWidth: 1, shouldShowStatus: true)
            profileViewModel?.statusBorderCode = config.look?.backgroundColor
            isUserAvailable = user.status == .available
        } else {
            title = config.workspace?.name ?? ""
            profileViewModel = nil
            isUserAvailable = nil
        }
    }
}
