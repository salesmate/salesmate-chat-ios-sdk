//
//  Configeration.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import UIKit
@_implementationOnly import SwiftyJSON

class Configeration {
    
    struct Availability {
        struct OfficeHour {
            let endTime: String
            let startTime: String
            let weekName: String
        }
        
        let replyTime: String
        let calculateResponseTimeInOfficeHours: Bool?
        let officeHours: [OfficeHour]?
        let timezone: String
    }
    
    struct lookAndFeel {
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
        let workspaceDescription: String
    }
    
    struct Rating {
        let id: String
        let label: String
        let unicode: String
    }
    
    let identity: Settings
    let environment: Environment
    
    var availability: Availability?
    var look: lookAndFeel?
    var welcome: Welcome?
    var workspace: Workspace?
    var users: [User]?
    var unread: [ConversationID]?
    var contact: Contact?
    var rating: [Rating]?
    
    var uniqueID: String? = "7caf763b-f7eb-4c54-8a99-8dcc0c120ee4"//UIDevice.current.identifierForVendor?.uuidString
    var contactID: IntegerID? { self.contact?.id }
    var verifiedID: IntegerID? = "102"
    
    var socketAuthToken: String?
    var pseudoName: String?
    var channels: [String]?
    
    init(connection: Settings, environment: Environment) {
        self.identity = connection
        self.environment = environment
    }
    
    func update(with detail: JSONObject) {
        let json = JSON(detail)
        
        if json["availability"].exists() {
            self.availability = Availability(from: json["availability"])
        }
        
        if json["lookAndFeel"].exists() {
            self.look = lookAndFeel(from: json["lookAndFeel"])
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
        case endTime = "endTime"
        case startTime = "startTime"
        case weekName = "weekName"
    }
}

extension Configeration.lookAndFeel: Codable {
    
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
        case id = "id"
        case label = "label"
        case unicode = "unicode"
    }
}
