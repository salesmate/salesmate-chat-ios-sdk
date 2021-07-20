//
//  ChatConnectionConfiguration.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 01/07/21.
//  Copyright © 2021 RapidOps Solution Private Limited. All rights reserved.
//

import Foundation

struct ChatConnectionConfiguration {
    let baseAPIPath: String
    let accessToken: String
    let webSocketLink: URL
    let linkName: String
    let userID: String

    var workspaceID: String?
    var csAuthToken: String?
    
    init(baseAPIPath: String, accessToken: String, webSocketLink: URL, linkName: String, userID: String) {
        self.baseAPIPath = baseAPIPath
        self.accessToken = accessToken
        self.webSocketLink = webSocketLink
        self.linkName = linkName
        self.userID = userID
    }
}
