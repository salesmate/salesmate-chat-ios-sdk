//
//  Configeration.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import UIKit
@_implementationOnly import SwiftyJSON

class Configeration {

    enum AskEmailSetting: String {
        case outsideOfficeHours = "only_outside_of_office_hours"
        case always = "always"
        case never = "never"
    }

    struct Availability {
        enum WeekDayName: String, Codable {
            case monday
            case tuesday
            case wednesday
            case thursday
            case friday
            case saturday
            case sunday

            case weekdays
            case weekends
        }

        struct OfficeHour {
            let endTime: String
            let startTime: String
            let weekName: WeekDayName
        }

        let replyTime: String
        let calculateResponseTimeInOfficeHours: Bool?
        let officeHours: [OfficeHour]?
        let timezone: String
    }

    struct LookAndFeel {
        let backgroundColor: String
        let actionColor: String
        let messengerBackground: String
        let logourl: String
        let showPoweredBy: Bool
    }

    struct Welcome {
        let language: String
        let greetingMessage: String
        let teamIntro: String
        let isDefault: Bool
    }

    struct Workspace {
        let id: String
        let linkname: String
        let name: String
        let workspaceDescription: String?
    }

    struct Rating {
        let id: String
        let label: String
        let unicode: String
    }

    struct Security {
        let canUploadAttachment: Bool
    }

    let identity: Settings
    let environment: Environment
    let local: Storage

    private(set) var availability: Availability?
    private(set) var look: LookAndFeel?
    private(set) var welcome: Welcome?
    private(set) var workspace: Workspace?
    private(set) var users: [User]?
    private(set) var unread: [ConversationID]?
    private(set) var contact: Contact?
    private(set) var rating: [Rating]?
    private(set) var askEmail: AskEmailSetting?
    private(set) var security: Security?

    /// We are assuming that we will alwayes get identifierForVendor because the chances of that is very low.
    let uniqueID: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
    var contactID: IntegerID? { self.contact?.id }
    var verifiedID: String?

    var socketAuthToken: String?
    var pseudoName: String?
    var channels: [String]?

    init(connection: Settings, environment: Environment, local: Storage = UserDefaultStorage()) {
        self.identity = connection
        self.environment = environment
        self.local = local

        if let pseudoName = local.pseudoName {
            self.pseudoName = pseudoName
        }

        if let socketAuthToken = local.socketAuthToken {
            self.socketAuthToken = socketAuthToken
        }
    }

    func saveRequireDataLocally() {
        local.pseudoName = pseudoName
        local.socketAuthToken = socketAuthToken
    }

    func update(with detail: JSONObject) {
        let json = JSON(detail)

        if json["availability"].exists() {
            self.availability = Availability(from: json["availability"])
        }

        if json["lookAndFeel"].exists() {
            self.look = LookAndFeel(from: json["lookAndFeel"])
        }

        if json["welcomeMessages"].exists(),
        let welcome = json["welcomeMessages"].array?.first(where: { $0["is_default"].boolValue }) {
            self.welcome = Welcome(from: welcome)
        }

        if json["workspaceData"].exists() {
            self.workspace = Workspace(from: json["workspaceData"])
        }

        if json["users"].exists() {
            self.users = json["users"].arrayValue.compactMap { User(from: $0) }
        }

        if json["unReadConversations"].exists() {
            self.unread = json["unReadConversations"].arrayObject as? [String]
        }

        if json["contactData"].exists() {
            self.contact = Contact(from: json["contactData"])
        }

        if json["emojiMapping"].exists() {
            self.rating = json["emojiMapping"].arrayValue.compactMap { Rating(from: $0) }
        }

        if let emailFrequency = json["upfrontEmailCollection"]["frequency"].string {
            self.askEmail = AskEmailSetting(rawValue: emailFrequency)
        }

        if json["securitySettings"].exists() {
            self.security = Security(from: json["securitySettings"])
        }
    }
}

extension Configeration {

    func isEmailAddressMandatory() -> Bool {
        guard contact?.email == nil else { return false }
        guard let askEmail = askEmail else { return false }

        switch askEmail {
        case .outsideOfficeHours: return true
        case .always: return true
        case .never: return false
        }
    }
}

extension Configeration.Availability: Codable {

    enum CodingKeys: String, CodingKey {
        case replyTime = "reply_time"
        case calculateResponseTimeInOfficeHours = "calculate_response_time_in_office_hours"
        case officeHours = "office_hours"
        case timezone
    }
}

extension Configeration.Availability.OfficeHour: Codable {

    enum CodingKeys: String, CodingKey {
        case endTime
        case startTime
        case weekName
    }
}

extension Configeration.LookAndFeel: Codable {

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case actionColor = "action_color"
        case messengerBackground = "messenger_background"
        case logourl = "logo_url"
        case showPoweredBy = "show_powered_by"
    }
}

extension Configeration.Welcome: Codable {

    enum CodingKeys: String, CodingKey {
        case language = "language"
        case greetingMessage = "greeting_message"
        case teamIntro = "team_intro"
        case isDefault = "is_default"
    }
}

extension Configeration.Workspace: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case linkname = "linkname"
        case name = "name"
        case workspaceDescription = "description"
    }
}

extension Configeration.Rating: Codable {

    enum CodingKeys: String, CodingKey {
        case id
        case label
        case unicode
    }
}

extension Configeration.Security: Codable {

    enum CodingKeys: String, CodingKey {
        case canUploadAttachment = "can_upload_attachment"
    }
}

extension Configeration.Availability.WeekDayName {

    static let allWeekDays: [Self] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let allWeekEndsDays: [Self] = [.saturday, .sunday]

    var isWeekDay: Bool { Self.allWeekDays.contains(self) }
    var isWeekendDay: Bool { Self.allWeekEndsDays.contains(self) }
}
