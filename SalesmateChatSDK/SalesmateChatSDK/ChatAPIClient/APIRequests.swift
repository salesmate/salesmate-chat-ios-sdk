//
//  APIRequests.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation
@_implementationOnly import HTTP

class CommonAPIComponents {
    
    static let shared: CommonAPIComponents = CommonAPIComponents()
    
    var base: URL = URL(string: "https://apis-dev.salesmate.io")!
    var headers: HTTPHeaders {
        return [HeaderKey.linkName: config?.identity.tenantID ?? "",
                HeaderKey.workspaceID: config?.identity.workspaceID ?? "",
                HeaderKey.verifiedID: config?.verifiedID?.description ?? "",
                HeaderKey.contactID: config?.contactID?.description ?? "",
                HeaderKey.uniqueID: config?.uniqueID ?? ""]
    }
    
    var config: Configeration?
}

struct PingRequest: HTTPRequest {
    
    var method: HTTPMethod = .post
    var path: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?
    
    init(common: CommonAPIComponents = CommonAPIComponents.shared) {
        path = URL(string: "messenger/v1/widget/ping", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["referer": common.config?.identity.tenantID ?? ""])
    }
}

struct GetSCAuthTokenRequest: HTTPRequest {
    
    var method: HTTPMethod = .post
    var path: URL
    var headers: HTTPHeaders?
    var body: HTTPBody?
    
    init(common: CommonAPIComponents = CommonAPIComponents.shared) {
        path = URL(string: "messenger/v1/widget/generate-token", relativeTo: common.base)!
        headers = common.headers
        body = JSONBody(["referer": common.config?.identity.tenantID ?? ""])
    }
}
