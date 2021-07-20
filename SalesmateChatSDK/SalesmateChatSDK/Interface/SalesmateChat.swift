//
//  SalesmateChat.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 20/07/21.
//

import Foundation
@_implementationOnly import Starscream

struct SalesmateChat {
    let client: WebSocket = WebSocket(request: URLRequest(url: URL(string: "wss://dev7.salesmate.io/socketcluster/")!))
    
    init() {}
    func connect() {
        client.connect()
    }
}
