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
            
            func getTimeIntervalSinceMidnightForTime(timeStr:String) -> TimeInterval{
                let formatter = DateFormatter();
                formatter.dateFormat = "h:mm a";
                let date = formatter.date(from: timeStr);
                let duration = (date?.timeIntervalSince1970 ?? 0) - (date?.getStartOfDay(timeZone: nil).timeIntervalSince1970 ?? 0)
                return abs(duration);
            }
        }

        let replyTime: String
        let calculateResponseTimeInOfficeHours: Bool?
        let officeHours: [OfficeHour]?
        let timezone: String
        
        func isCurrentTimeFallsUnderOfficeHours() -> Bool{
            guard let ofcHours = self.officeHours else{
                return false;
            }
            
            let timeZone = TimeZone(abbreviation: timezone);
            let currentWeekDayName = Date().getDayWithTimezone(timeZone: timeZone);
            
            guard let weekDayName = WeekDayName(rawValue: currentWeekDayName.lowercased()) else{
                return false;
            }
            
            let weekDays:[WeekDayName] = [.monday, .tuesday, .wednesday, .thursday, .friday];
            let weekEnds:[WeekDayName] = [.saturday, .sunday];
            
            let timeIntervalSinceMidnight = abs(Date().getTimeIntervalSinceMidnightWithTimezone(timeZone: timeZone));
            
            var isInOfficeHours = false;
            for ofcHour in ofcHours{
                if ofcHour.weekName == weekDayName || (ofcHour.weekName == .weekdays && weekDays.contains(weekDayName)) || (ofcHour.weekName == .weekends && weekEnds.contains(weekDayName)){
                    let startTimeInterval = ofcHour.getTimeIntervalSinceMidnightForTime(timeStr: ofcHour.startTime)
                    let endTimeInterval = ofcHour.getTimeIntervalSinceMidnightForTime(timeStr: ofcHour.endTime);
                    if timeIntervalSinceMidnight > startTimeInterval && timeIntervalSinceMidnight < endTimeInterval{
                        isInOfficeHours = true;
                        break;
                    }
                }
            }
            return isInOfficeHours;
        }
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

    struct ClosedConversation {
        let preventRepliesForContacts: Bool
        let preventRepliesForVisitors: Bool
        let preventRepliesInDaysForContacts: IntegerID
        let preventRepliesInDaysForVisitors: IntegerID
    }

    struct MICS {
        let shouldPlaySoundsForMessage: Bool
    }

    struct TeamNextAvailableTime {
        let fromNow: String?
        let availableAt: String?
        
        var availableAtDate: Date? {
            guard let closedDateString = availableAt else { return nil }
            if let date = DateFormatter.fullISO8601NoFraction.date(from: closedDateString) {
                return date
            } else if let date = DateFormatter.fullISO8601.date(from: closedDateString) {
                return date
            } else if let date = DateFormatter.fullISO8601WithoutZ.date(from: closedDateString) {
                return date
            }
            
            return nil
        }
        
        var isPastTime: Bool {
            guard let availableAtDate = availableAtDate else { return false }
            if availableAtDate.timeIntervalSinceNow.sign == .minus {
                return true
            } else {
                return false
            }
        }
    }
    
    let identity: Configuration
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
    private(set) var closed: ClosedConversation?
    private(set) var other: MICS?
    private(set) var canStartNewConversation: Bool = false
    private(set) var teamNextAvailableTime: TeamNextAvailableTime?

    /// We are assuming that we will alwayes get identifierForVendor because the chances of that is very low.
    var uniqueID: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
    var contactID: IntegerID? { self.contact?.id }
    var verifiedID: String?

    var socketAuthToken: String?
    var pseudoName: String?
    var channels: [String]?

    init(connection: Configuration, environment: Environment, local: Storage = UserDefaultStorage()) {
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

        if json["pseudoName"].exists(){
            self.pseudoName = json["pseudoName"].stringValue;
        }
        
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

        if json["conversationsSettings"].exists() {
            self.closed = ClosedConversation(from: json["conversationsSettings"])
        }

        if json["misc"].exists() {
            self.other = MICS(from: json["misc"])
        }

        if json["teamNextAvailableTime"].exists() {
            self.teamNextAvailableTime = TeamNextAvailableTime(from: json["teamNextAvailableTime"])
        }

        canStartNewConversation = json["canVisitorOrContactStartNewConversation"].bool ?? false
        self.saveRequireDataLocally()
    }

    func updateStatus(of user: UserID, to status: User.Status) {
        guard let index = users?.firstIndex(where: { $0.id == user }) else { return }
        users?[index].status = status
    }
}

extension Configeration {

    func isContactDetailMandatory() -> Bool {
        guard contact?.email == nil else { return false }
        guard let askEmail = askEmail else { return false }

        switch askEmail {
        case .outsideOfficeHours: return !(self.availability?.isCurrentTimeFallsUnderOfficeHours() ?? true)
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
    
    func isCurrentTimeInOfficeHours(){
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

extension Configeration.ClosedConversation: Codable {

    enum CodingKeys: String, CodingKey {
        case preventRepliesForContacts = "prevent_replies_to_close_conversations_for_contacts"
        case preventRepliesForVisitors = "prevent_replies_to_close_conversations_for_visitors"
        case preventRepliesInDaysForContacts = "prevent_replies_to_close_conversations_within_number_of_days_for_contacts"
        case preventRepliesInDaysForVisitors = "prevent_replies_to_close_conversations_within_number_of_days_for_visitors"
    }
}

extension Configeration.MICS: Codable {

    enum CodingKeys: String, CodingKey {
        case shouldPlaySoundsForMessage = "play_sounds_for_messenger"
    }
}

extension Configeration.TeamNextAvailableTime: Codable {
    enum CodingKeys: String, CodingKey {
        case fromNow = "fromNow"
        case availableAt = "availableAt"
    }
}

extension Configeration.Availability.WeekDayName {

    static let allWeekDays: [Self] = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let allWeekEndsDays: [Self] = [.saturday, .sunday]

    var isWeekDay: Bool { Self.allWeekDays.contains(self) }
    var isWeekendDay: Bool { Self.allWeekEndsDays.contains(self) }
}

extension Configeration {

    var shouldPreventReplies: Bool {
        if contactID == nil {
            return closed?.preventRepliesForVisitors ?? false
        } else {
            return closed?.preventRepliesForContacts ?? false
        }
    }

    var preventRepliesInDays: Int {
        if contactID == nil {
            return Int(closed?.preventRepliesInDaysForVisitors.description ?? "0") ?? 0
        } else {
            return Int(closed?.preventRepliesInDaysForContacts.description ?? "0") ?? 0
        }
    }
}
