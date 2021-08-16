//
//  ChatAPI.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import Foundation

protocol ChatAPI: AnyObject {
    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void))
    func getAuthToken(completion: @escaping (Result<(pseudoName: String, authToken: String, channels: [String]), ChatError>) -> Void)

    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void)
    func getDetail(of conversation: ConversationID, completion: @escaping (Result<Conversation, ChatError>) -> Void)

    func getMessages(of conversation: ConversationID, at page: Page, completion: @escaping (Result<[Message], ChatError>) -> Void)
    func getMessages(of conversation: ConversationID, from date: Date, completion: @escaping (Result<[Message], ChatError>) -> Void)

    func send(message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, ChatError>) -> Void)

    func upload(file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping (Result<UploadedFile, ChatError>) -> Void)
}
