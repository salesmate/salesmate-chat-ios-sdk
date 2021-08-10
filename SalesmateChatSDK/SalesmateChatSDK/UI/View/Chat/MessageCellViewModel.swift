//
//  MessageCellViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import Foundation

class ChatAttachmentViewModel {
    private let file: File

    let filename: String

    init(file: File) {
        self.file = file

        filename = file.name ?? ""
    }
}

class MessageViewModel {

    enum Alignment {
        case left
        case right
    }

    enum Content {
        case html(NSAttributedString)
        case image(ChatAttachmentViewModel)
        case file(ChatAttachmentViewModel)
    }

    enum IsDeleted {
        case yes(String, Int) // Message, Transparency in percentage.
        case no
    }

    // MARK: - Properties
    let profileViewModel: CirculerProfileViewModelType?
    let contents: [Content]
    let alignment: Alignment
    let backgroundColorCode: String
    let time: String
    let isDeleted: IsDeleted

    // MARK: - Private Properties
    private let message: Message
    private let look: Configeration.LookAndFeel

    // MARK: - Init
    init(message: Message, look: Configeration.LookAndFeel, users: [User]) {
        self.message = message
        self.look = look
        self.time = message.createdDate.durationString
        self.alignment = Self.alignment(for: message)
        self.profileViewModel = Self.profileViewModel(for: message, users: users)
        self.backgroundColorCode = Self.backgroundColorCode(for: message, look: look)
        self.contents = Self.contentViewModels(for: message)
        self.isDeleted = (message.deletedDate == nil) ? .no : .yes("This message was deleted.", 50)
    }

    private static func alignment(for message: Message) -> Alignment {
        message.userID == nil ? .right : .left
    }

    private static func profileViewModel(for message: Message, users: [User]) -> CirculerProfileViewModelType? {
        guard let userID = message.userID else { return nil }
        guard let user = users.first(where: { $0.id == userID }) else { return nil }

        return CirculerUserProfileViewModel(user: user)
    }

    private static func backgroundColorCode(for message: Message, look: Configeration.LookAndFeel) -> String {
        message.userID == nil ? look.actionColor : "EDF0F7"
    }

    private static func contentViewModels(for message: Message) -> [Content] {
        guard let messageContent = message.contents, !messageContent.isEmpty else { return [] }

        var contents: [Content] = []

        for block in messageContent {
            switch block.blockType {
            case .text, .html, .orderedList, .unorderedList:
                guard let text = block.text?.attributedString else { continue }
                contents.append(.html(text))
            case .image:
                guard let file = block.file else { continue }
                contents.append(.file(ChatAttachmentViewModel(file: file)))
            case .file:
                guard let file = block.file else { continue }
                contents.append(.file(ChatAttachmentViewModel(file: file)))
            }
        }

        return contents
    }
}
