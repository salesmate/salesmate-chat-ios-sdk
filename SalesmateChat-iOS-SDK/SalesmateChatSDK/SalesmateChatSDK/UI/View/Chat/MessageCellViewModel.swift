//
//  MessageCellViewModel.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 04/08/21.
//

import Foundation

enum ChatRow {
    case message(MessageViewModelType)
    case askEmail(AskEmailViewModel)
    case askRating(AskRatingViewModel)
}

enum CellAlignment {
    case left
    case right
}

enum CellContent {
    case html(NSAttributedString)
    case image(ChatAttachmentViewModel)
    case file(ChatAttachmentViewModel)
}

enum CellBottom {
    case text(String)
    case retry
}

enum IsDeleted {
    case yes(String, Int) // Message, Transparency in percentage.
    case no
}

protocol ChatContentViewModelType: AnyObject {
    var id: MessageID { get }
    var profileViewModel: CirculerProfileViewModelType? { get }
}

class AskEmailViewModel: ChatContentViewModelType {
    let id: MessageID
    let profileViewModel: CirculerProfileViewModelType?
    let actionColorCode: String
    var email: String? = ""

    init(message: Message, look: Configeration.LookAndFeel) {
        id = message.id
        profileViewModel = CirculerBotProfileViewModel()
        actionColorCode = look.actionColor
    }
}

class AskRatingViewModel: ChatContentViewModelType {
    private let config: [Configeration.Rating]

    let id: MessageID = ""
    let profileViewModel: CirculerProfileViewModelType? = CirculerBotProfileViewModel()
    let actionColorCode: String
    let ratingEmojies: [String]

    private(set) var rating: Int?
    private(set) var ratingText: String?
    private(set) var remark: String?

    init(config: [Configeration.Rating], look: Configeration.LookAndFeel, rating: String? = nil, remark: String? = nil) {
        self.config = config
        self.actionColorCode = look.actionColor

        if let rating = rating {
            self.rating = Int(rating)
            self.ratingText = config.first(where: { $0.id == rating })?.label
        }

        self.ratingEmojies = config.map({ rating in
            String(UnicodeScalar(Int(rating.unicode, radix: 16)!)!) + "\u{FE0F}"
        })
        self.remark = remark
    }
}

protocol MessageViewModelType: ChatContentViewModelType {
    var alignment: CellAlignment { get }
    var contents: [CellContent] { get }

    var backgroundColorCode: String { get }
    var actionColorCode: String { get }

    var isDeleted: IsDeleted { get }
    var email: String? { get }
    var bottom: CellBottom { get }

    var didUpdateBotton: (() -> Void)? { get set }
}

class ChatAttachmentViewModel {

    private let file: File?
    private let fileToSend: FileToUpload?
    private let uploadedFile: UploadedFile?

    let filename: String
    let data: Data?
    let url: URL?

    init(file: File) {
        self.file = file
        self.fileToSend = nil
        self.uploadedFile = nil

        self.filename = file.name ?? ""
        self.url = file.locationURL
        self.data = nil
    }

    init(file: FileToUpload) {
        self.file = nil
        self.fileToSend = file
        self.uploadedFile = nil

        self.filename = file.fileName
        self.url = nil
        self.data = file.fileData
    }

    init(file: UploadedFile) {
        self.file = nil
        self.fileToSend = nil
        self.uploadedFile = file

        self.filename = file.name
        self.url = URL(string: file.location)
        self.data = nil
    }
}

class MessageViewModel: MessageViewModelType {

    // MARK: - Properties
    let id: MessageID
    let profileViewModel: CirculerProfileViewModelType?
    let contents: [CellContent]
    let alignment: CellAlignment
    let backgroundColorCode: String
    let actionColorCode: String
    let isDeleted: IsDeleted
    let email: String?

    var bottom: CellBottom {
        didSet { runOnMain { self.didUpdateBotton?() } }
    }

    var isSeen: Bool? {
        didSet { updateBottomText() }
    }

    var didUpdateBotton: (() -> Void)?

    // MARK: - Private Properties
    private let message: Message
    private let look: Configeration.LookAndFeel

    // MARK: - Init
    init(message: Message, look: Configeration.LookAndFeel, users: [User], ratings: [Configeration.Rating]) {
        self.message = message
        self.look = look

        self.id = message.id
        self.bottom = .text(Self.bottomText(from: message.createdDate, isSeen: isSeen))
        self.alignment = Self.alignment(for: message)
        self.profileViewModel = Self.profileViewModel(for: message, users: users)
        self.backgroundColorCode = Self.backgroundColorCode(for: message, look: look)
        self.actionColorCode = Self.actionColorCode(for: message, look: look)
        self.contents = Self.contentViewModels(for: message)
        self.isDeleted = (message.deletedDate == nil) ? .no : .yes("This message was deleted.", 50)
        self.email = message.contactEmail
    }

    private static func alignment(for message: Message) -> CellAlignment {
        message.userID == nil && !message.isBot ? .right : .left
    }

    private static func profileViewModel(for message: Message, users: [User]) -> CirculerProfileViewModelType? {
        if message.isBot {
            return CirculerBotProfileViewModel()
        }

        guard let userID = message.userID else { return nil }
        guard let user = users.first(where: { $0.id == userID }) else { return nil }

        return CirculerUserProfileViewModel(user: user)
    }

    private static func backgroundColorCode(for message: Message, look: Configeration.LookAndFeel) -> String {
        message.userID == nil && !message.isBot ? look.actionColor : "EDF0F7"
    }

    private static func actionColorCode(for message: Message, look: Configeration.LookAndFeel) -> String {
        look.actionColor
    }

    private static func contentViewModels(for message: Message) -> [CellContent] {
        guard let messageContent = message.contents, !messageContent.isEmpty else { return [] }

        var contents: [CellContent] = []

        for block in messageContent {
            switch block.type {
            case .text, .html, .orderedList, .unorderedList:
                guard let text = block.text?.attributedString else { continue }
                contents.append(.html(text))
            case .image:
                guard let file = block.file else { continue }
                contents.append(.image(ChatAttachmentViewModel(file: file)))
            case .file:
                guard let file = block.file else { continue }
                contents.append(.file(ChatAttachmentViewModel(file: file)))
            }
        }

        return contents
    }

    private func updateBottomText() {
        bottom = .text(Self.bottomText(from: message.createdDate, isSeen: isSeen))
    }

    private static func bottomText(from date: Date, isSeen: Bool?) -> String {
        var text = date.durationString

        if let isSeen = isSeen {
            text += " " + (isSeen ? "Seen" : "Not seen yet")
        }

        return text
    }
}

class SendingMessageViewModel: MessageViewModelType {

    // MARK: - Properties
    let id: MessageID
    let profileViewModel: CirculerProfileViewModelType? = nil
    let contents: [CellContent]
    let alignment: CellAlignment = .right
    let backgroundColorCode: String
    let actionColorCode: String
    let isDeleted: IsDeleted = .no
    let email: String? = nil
    let bottom: CellBottom

    var didUpdateBotton: (() -> Void)?

    // MARK: - Private Properties
    private let message: MessageToSend
    private let look: Configeration.LookAndFeel

    // MARK: - Init
    init(message: MessageToSend, look: Configeration.LookAndFeel, users: [User]) {
        self.message = message
        self.look = look

        self.id = message.id
        self.backgroundColorCode = look.actionColor
        self.actionColorCode = look.actionColor
        self.contents = Self.contentViewModels(for: message)
        self.bottom = Self.cellBottom(for: message)
    }

    private static func contentViewModels(for message: MessageToSend) -> [CellContent] {
        var contents: [CellContent] = []

        for block in message.contents {
            switch block.type {
            case .text:
                guard let text = block.text?.attributedString else { continue }
                contents.append(.html(text))
            default:
                break
            }
        }

        if let file = message.fileToUpload {
            if file.mimeType.contains("image") {
                contents.append(.image(ChatAttachmentViewModel(file: file)))
            } else {
                contents.append(.file(ChatAttachmentViewModel(file: file)))
            }
        } else if let file = message.uploadedFile {
            if file.mimeType.contains("image") {
                contents.append(.image(ChatAttachmentViewModel(file: file)))
            } else {
                contents.append(.file(ChatAttachmentViewModel(file: file)))
            }
        }

        return contents
    }

    private static func cellBottom(for message: MessageToSend) -> CellBottom {
        switch message.status {
        case .sending:
            return .text("Sending...")
        case .sent:
            return .text("\(message.createdDate.durationString) Not seen yet")
        case .fail:
            return .retry
        }
    }
}
