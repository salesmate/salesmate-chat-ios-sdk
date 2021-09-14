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

    init(socketAuthToken: String?, pseudoName: String?, common: CAC = common) {
        url = URL(string: "messenger/v1/widget/generate-token", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["accessToken": socketAuthToken, "pseudo_name": pseudoName])
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

struct SendMessagesRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var queryItems: [URLQueryItem]?
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(conversationID: String, message: MessageToSend, common: CAC = common) {
        url = URL(string: "messenger/v1/conversations/\(conversationID)/message", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(message)
    }
}

struct SingleFileUploadRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var queryItems: [URLQueryItem]? = [URLQueryItem(name: "make_public", value: "true")]
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(fileName: String, fileData: Data, mimeType: String, common: CAC = common) {
        url = URL(string: "/messenger/v1/upload-file", relativeTo: common.base)!
        headers = common.headers
        body = MultipartSingleFileBody(fileName: fileName, fileData: fileData, mimeType: mimeType)
    }
}

struct CreateContactRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(email: String, conversationID: String?, common: CAC = common) {
        url = URL(string: "/messenger/v1/contact", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["email": email, "conversation_id": conversationID])
    }
}

struct DownloadTranscriptRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?

    init(conversationID: String, common: CAC = common) {
        url = URL(string: "/messenger/v1/conversations/\(conversationID)/download-transcript", relativeTo: common.base)!
        headers = common.headers
    }
}

struct UpdateRatingRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(conversationID: String, rating: Int, common: CAC = common) {
        url = URL(string: "/messenger/v1/conversations/\(conversationID)/rating", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["rating": rating])
    }
}

struct UpdateRemarkRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(conversationID: String, remark: String, common: CAC = common) {
        url = URL(string: "/messenger/v1/conversations/\(conversationID)/remark", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["remark": remark])
    }
}

struct ReadConversationRequest: HTTPRequest {

    var method: HTTPMethod = .post
    var url: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?

    init(conversationID: String, common: CAC = common) {
        url = URL(string: "/messenger/v1/widget/read-conversation-for-visitor", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["conversation_id": conversationID])
    }
}
