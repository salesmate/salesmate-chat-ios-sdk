//
//  SalesmateChat.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 20/07/21.
//

import Foundation

struct Settings {
    let workspace_id: String
    let app_key: String
    let tenant_id: String
}

protocol SalesmateChat {
    static func setSalesmateChat(configeration settings: Settings)
}

class SalesmateChatSDK: SalesmateChat {

    private var environment: Environment
    private var client: ChatClient
    private var settings: Settings
    
    private static var shared: SalesmateChatSDK?
    
    init(with settings: Settings) {
        self.environment = .development
        self.settings = settings
        self.client = SalesmateChatClient(chatStream: StarscreamChatStream(for: URL(string: "")!), chatAPI: ChatAPIClient())
    }
    
    static func setSalesmateChat(configeration settings: Settings) {
        shared = SalesmateChatSDK(with: settings)
        
        shared?.client.connect(waitForFullConnection: false, completion: { _ in
            
        })
    }
}
