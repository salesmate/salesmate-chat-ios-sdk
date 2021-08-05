//
//  MessageCellViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import Foundation

class MessageViewModel {

    enum Alignment {
        case left
        case right
    }

    enum Content {
        case html(NSAttributedString)
        case image
        case file
    }

    // MARK: - Properties
    let profileViewModel: CirculerProfileViewModelType?
    let contents: [Content]
    let alignment: Alignment
    let backgroundColorCode: String
    let time: String

    // MARK: - Private Properties
    private let message: Message
    private let look: Configeration.LookAndFeel

    // MARK: - Init
    init(message: Message, look: Configeration.LookAndFeel, users: [User]) {
        self.message = message
        self.look = look
        self.time = message.createdDate.durationString

        if message.userID == nil {
            alignment = .right
            backgroundColorCode = look.backgroundColor
            profileViewModel = nil
        } else {
            alignment = .left
            backgroundColorCode = "EDF0F7"

            if let user = users.first(where: { $0.id == message.userID }) {
                profileViewModel = CirculerUserProfileViewModel(user: user)
            } else {
                profileViewModel = nil
            }
        }

        self.contents = Self.prepareContentViewModels(for: message)
    }

    private static func prepareContentViewModels(for message: Message) -> [Content] {
        guard let messageContent = message.contents, !messageContent.isEmpty else { return [] }

        var contents: [Content] = []

        for block in messageContent {
            switch block.blockType {
            case .text, .html, .orderedList, .unorderedList:
                guard let text = block.text?.attributedString else { continue }

                contents.append(.html(text))
            case .image:
                break
            case .file:
                break
            }
        }

        return contents
    }
}
