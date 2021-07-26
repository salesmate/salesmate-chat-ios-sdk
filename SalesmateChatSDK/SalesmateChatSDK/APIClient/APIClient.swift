//
//  APIClient.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation
@_implementationOnly import HTTP

class ChatAPIClient: ChatAPI {
    
    private let loader: (RequestLoader & RequestUploader)
    
    init(loader: (RequestLoader & RequestUploader) = APIRequestLoader()) {
        self.loader = loader
    }
}
