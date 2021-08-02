//
//  Visitor.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 07/07/21.
//  Copyright © 2021 RapidOps Solution Private Limited. All rights reserved.
//

import Foundation

struct Visitor {
    let visitorID: String?
    let tenantID: String?
    let contactID: String?
    let currentURL: String?
    let totalSessions: String?
    let lastSeen: String?
    let lastCommunicationDate: Date?
    let lastCommunicationReceivedDate: Date?
    let country: String?
    let region: String?
    let city: String?
    let timezone: String?
    let continentCode: String?
    let browserLanguage: String?
    let browser: String?
    let browserVersion: String?
    let os: String?
    let utmCampaign: String?
    let utmContent: String?
    let utmMedium: String?
    let utmSource: String?
    let utmTerm: String?
    let referralURL: String?
}

extension Visitor: Codable {

    enum CodingKeys: String, CodingKey {
        case visitorID = "visitorId"
        case tenantID = "tenantId"
        case contactID = "contactId"
        case currentURL = "currentUrl"
        case totalSessions = "totalSessions"
        case lastSeen = "lastSeen"
        case lastCommunicationDate = "lastCommunicationDate"
        case lastCommunicationReceivedDate = "lastCommunicationReceivedDate"
        case country = "country"
        case region = "region"
        case city = "city"
        case timezone = "timezone"
        case continentCode = "continentCode"
        case browserLanguage = "browserLanguage"
        case browser = "browser"
        case browserVersion = "browserVersion"
        case os = "os"
        case utmCampaign = "utmCampaign"
        case utmContent = "utmContent"
        case utmMedium = "utmMedium"
        case utmSource = "utmSource"
        case utmTerm = "utmTerm"
        case referralURL = "referralUrl"
    }
}
