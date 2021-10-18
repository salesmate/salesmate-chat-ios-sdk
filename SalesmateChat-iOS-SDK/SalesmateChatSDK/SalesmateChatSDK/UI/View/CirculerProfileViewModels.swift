//
//  CirculerProfileViewModels.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 05/08/21.
//

import Foundation

protocol CirculerProfileViewModelType {
    var borderWidth: Float { get }
    var backgroundColorCode: String { get }

    var image: ImageSource? { get }

    var text: String? { get }
    var textColorCode: String { get }
    var textSize: Float { get }

    var shouldShowStatus: Bool { get }
    var statusColorCode: String? { get }
    var statusBorderCode: String? { get }
}

extension CirculerProfileViewModelType {

    var shouldShowStatus: Bool { false }
    var statusColorCode: String? { nil }
    var statusBorderCode: String? { nil }

    private static var colorCodesForProfilePicBG: [String] {[
        "ff5622", "8157ff", "4d88ff",
        "ff416a", "683ab7", "03a8f4",
        "26c5da", "00ac7c", "c0ca33",
        "ffb301", "00cc88"
    ]}

    static func profileBackgroundColorCode(for name: String) -> String {
        var totalValue: Int = 0

        for character in name.utf8 {
            let stringSegment = "\(character)"
            let intValue = Int(stringSegment)!
            totalValue += intValue
        }

        let index = totalValue % colorCodesForProfilePicBG.count
        return colorCodesForProfilePicBG[index]
    }
}

class CirculerUserProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: Float
    let backgroundColorCode: String

    let image: ImageSource?

    let text: String?
    let textColorCode: String = "FFFFFF"
    let textSize: Float = 18

    let shouldShowStatus: Bool
    var userStatus: User.Status?
    var statusColorCode: String? {
        guard let userStatus = userStatus else { return nil }
        switch userStatus {
        case .available: return "00D890"
        case .away: return "FFC300"
        }
    }
    var statusBorderCode: String? = "FFFFFF"

    private let user: User

    init(user: User, borderWidth: Float = 0, shouldShowStatus: Bool = false) {
        self.user = user
        self.borderWidth = borderWidth
        self.shouldShowStatus = shouldShowStatus
        self.userStatus = user.status

        text = user.firstName.first?.description

        if let url = URL(string: user.profileUrl ?? "") {
            image = .url(url)
        } else {
            image = nil
        }

        backgroundColorCode = Self.profileBackgroundColorCode(for: user.firstName)
    }
}

class CirculerMoreProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: Float
    let backgroundColorCode: String = "EBECF0"

    let image: ImageSource? = nil

    let text: String?
    let textSize: Float = 18
    let textColorCode: String = "505F79"

    private let count: Int

    init(count: Int, borderWidth: Float = 0) {
        self.count = count
        self.borderWidth = borderWidth

        text = "+\(count)"
    }
}

class CirculerTextProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: Float = 0
    let backgroundColorCode: String

    let image: ImageSource? = nil

    let text: String?
    let textColorCode: String = "FFFFFF"
    let textSize: Float = 18

    init(text: String) {
        self.text = text.first?.description
        self.backgroundColorCode = Self.profileBackgroundColorCode(for: text)
    }
}

class CirculerBotProfileViewModel: CirculerProfileViewModelType {

    let borderWidth: Float = 0
    let backgroundColorCode: String

    let image: ImageSource? = .local("img-bot-avatar")

    let text: String? = "B"
    let textColorCode: String = "FFFFFF"
    let textSize: Float = 14

    init() {
        self.backgroundColorCode = Self.profileBackgroundColorCode(for: "Bot")
    }
}
