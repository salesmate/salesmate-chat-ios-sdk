//
//  ChatAPI.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import Foundation

protocol ChatAPI: AnyObject {
    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void))
    func getAuthToken(completion: @escaping (Result<(pseudoName: String, authToken:String, channels: [String]), ChatError>) -> Void)
}
