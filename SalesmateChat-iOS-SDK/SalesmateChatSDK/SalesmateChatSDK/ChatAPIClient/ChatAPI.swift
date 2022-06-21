//
//  ChatAPI.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 27/07/21.
//

import Foundation

protocol ChatAPI: AnyObject {
    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void))
    func getAuthToken(with socketAuthToken: String?, pseudoName: String?, completion: @escaping (Result<(pseudoName: String, authToken: String, channels: [String]), ChatError>) -> Void)
    func createContact(with email: String, in conversation: ConversationID?, completion: @escaping (Result<Void, ChatError>) -> Void)

    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void)
    func getDetail(of conversation: ConversationID, completion: @escaping (Result<Conversation, ChatError>) -> Void)
    func downloadTranscript(of ID: ConversationID, completion: @escaping ((Result<String, ChatError>) -> Void))

    func updateRating(of ID: ConversationID, to rating: Int, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func updateRemark(of ID: ConversationID, to remark: String, completion: @escaping ((Result<Void, ChatError>) -> Void))
    func readConversation(ID: ConversationID, completion: @escaping ((Result<Void, ChatError>) -> Void))

    func getMessages(of conversation: ConversationID, at page: Page, completion: @escaping (Result<[Message], ChatError>) -> Void)
    func getMessages(of conversation: ConversationID, from date: Date, completion: @escaping (Result<[Message], ChatError>) -> Void)

    func send(message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, ChatError>) -> Void)

    func upload(file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping (Result<UploadedFile, ChatError>) -> Void)
    
    func createLogin(with loginUser: LoginUser, completion: @escaping (Result<String, ChatError>) -> Void)

    func sendDeviceToken(with deviceToken: String, deviceId: String, completion: @escaping (Result<Void, ChatError>) -> Void)
}
