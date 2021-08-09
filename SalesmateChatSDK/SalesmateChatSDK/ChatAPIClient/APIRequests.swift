//
//  APIRequests.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

class CommonAPIComponents {

    static let shared: CommonAPIComponents = CommonAPIComponents()

    var config: Configeration?
    var base: URL { config?.environment.baseAPIURL ?? Environment.current.baseAPIURL }
    var headers: HTTPHeaders {
        return [HeaderKey.linkName: config?.identity.tenantID ?? "",
                HeaderKey.workspaceID: config?.identity.workspaceID ?? "",
                HeaderKey.verifiedID: config?.verifiedID?.description ?? "",
                HeaderKey.contactID: config?.contactID?.description ?? "",
                HeaderKey.uniqueID: config?.uniqueID ?? ""]
    }
}

// Define to make syntex short.
typealias CAC = CommonAPIComponents
private let common = CommonAPIComponents.shared

struct PingRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(common: CAC = common) {
        url = URL(string: "messenger/v1/widget/ping", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["referer": common.config?.identity.tenantID ?? ""])
    }
}

struct GetSCAuthTokenRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(common: CAC = common) {
        url = URL(string: "messenger/v1/widget/generate-token", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["referer": common.config?.identity.tenantID ?? ""])
    }
}

struct GetConversationsRequest: HTTPRequest {

    var method: HTTPMethod = .get
    var url: URL
    var queryItems: [URLQueryItem]?
    var headers: HTTPHeaders?

    init(rows: Int, offset: Int, common: CAC = common) {
        url = URL(string: "messenger/v1/widget/conversations", relativeTo: common.base)!
        queryItems = [URLQueryItem(name: "rows", value: String(rows)),
                      URLQueryItem(name: "offset", value: String(offset))]
        headers = common.headers
    }
}

struct GetConversationDetailRequest: HTTPRequest {

    var method: HTTPMethod = .get
    var url: URL
    var queryItems: [URLQueryItem]?
    var headers: HTTPHeaders?

    init(conversationID: String, common: CAC = common) {
        url = URL(string: "messenger/v1/widget/conversations/\(conversationID)", relativeTo: common.base)!
        queryItems = [URLQueryItem(name: "messages", value: "true")]
        headers = common.headers
    }
}

struct GetMessagesRequest: HTTPRequest {

    var method: HTTPMethod = .get
    var url: URL
    var queryItems: [URLQueryItem]?
    var headers: HTTPHeaders?

    init(conversationID: String, rows: Int, offset: Int, common: CAC = common) {
        url = URL(string: "messenger/v1/widget/conversations/\(conversationID)/messages", relativeTo: common.base)!
        queryItems = [URLQueryItem(name: "rows", value: String(rows)),
                      URLQueryItem(name: "offset", value: String(offset))]
        headers = common.headers
    }
}

struct GetLatestMessagesRequest: HTTPRequest {

    var method: HTTPMethod = .get
    var url: URL
    var queryItems: [URLQueryItem]?
    var headers: HTTPHeaders?

    init(conversationID: String, fromDate: Date, common: CAC = common) {
        url = URL(string: "messenger/v1/widget/conversations/\(conversationID)/messages", relativeTo: common.base)!
        queryItems = [URLQueryItem(name: "rows", value: "10"),
                      URLQueryItem(name: "offset", value: "0"),
                      URLQueryItem(name: "lastMessageDate", value: fromDate.stringAsISO8601Format)]
        headers = common.headers
    }
}
