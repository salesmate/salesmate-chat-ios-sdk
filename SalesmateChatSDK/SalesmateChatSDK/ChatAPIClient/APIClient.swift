//
//  APIClient.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

class ChatAPIClient {

    private let loader: (RequestLoader & RequestUploader)

    init(config: Configeration, loader: (RequestLoader & RequestUploader) = APIRequestLoader()) {
        self.loader = loader

        CommonAPIComponents.shared.config = config
    }
}

extension ChatAPIClient: ChatAPI {

    func getConfigerations(completion: @escaping ((Result<JSONObject, ChatError>) -> Void)) {
        let request = PingRequest()

        loader.load(request: request) { result in
            switch result {
            case .success(let response):
                guard let config = response.json as? JSONObject else { return }
                completion(.success(config))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func getAuthToken(with socketAuthToken: String?, pseudoName: String?, completion: @escaping (Result<(pseudoName: String, authToken: String, channels: [String]), ChatError>) -> Void) {
        let request = GetSCAuthTokenRequest(socketAuthToken: socketAuthToken, pseudoName: pseudoName)

        loader.load(request: request) { (result) in
            switch result {
            case .success(let response):
                guard let json = response.json as? JSONObject else { return }
                guard let pseudoName = json["pseudoName"] as? String else { return }
                guard let authToken = json["authToken"] as? String else { return }
                guard let channel = json["channel"] as? JSONObject else { return }
                guard let channels = (channel["channels"] as? JSONObject)?.map({ $0.value }) as? [String] else { return }

                completion(.success((pseudoName: pseudoName, authToken: authToken, channels: channels)))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func getConversations(at page: Page, completion: @escaping (Result<[Conversation], ChatError>) -> Void) {
        let request = GetConversationsRequest(rows: page.rows, offset: page.offset)

        loader.load(request: request) { (result) in
            switch result {
            case .success(let response):
                guard let json = response.json as? JSONArray else { return }
                let conversations = json.compactMap { Conversation(from: $0) }
                completion(.success(conversations))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func getDetail(of conversation: ConversationID, completion: @escaping (Result<Conversation, ChatError>) -> Void) {
        let request = GetConversationDetailRequest(conversationID: conversation)

        loader.load(request: request) { (result) in
            switch result {
            case .success(let response):
                guard let conversationDetail = response.json as? JSONObject else { return }
                guard let conversation = Conversation(from: conversationDetail) else { return }

                completion(.success(conversation))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func downloadTranscript(of ID: ConversationID, completion: @escaping ((Result<String, ChatError>) -> Void)) {
        let request = DownloadTranscriptRequest(conversationID: ID)

        loader.load(request: request) { result in
            switch result {
            case .success(let response):
                guard let base64EncodedString = response.body?.utf8 else { return }
                guard let data = Data(base64Encoded: base64EncodedString, options: .ignoreUnknownCharacters) else { return }
                guard let decodedString = String(data: data, encoding: .utf8) else { return }

                completion(.success(decodedString))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func updateRating(of ID: ConversationID, to rating: Int, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        let request = UpdateRatingRequest(conversationID: ID, rating: rating)

        loader.load(request: request) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure: completion(.failure(.unknown))
            }
        }
    }

    func updateRemark(of ID: ConversationID, to remark: String, completion: @escaping ((Result<Void, ChatError>) -> Void)) {
        let request = UpdateRemarkRequest(conversationID: ID, remark: remark)

        loader.load(request: request) { result in
            switch result {
            case .success: completion(.success(()))
            case .failure: completion(.failure(.unknown))
            }
        }
    }

    func getMessages(of conversation: ConversationID, at page: Page, completion: @escaping (Result<[Message], ChatError>) -> Void) {
        let request = GetMessagesRequest(conversationID: conversation, rows: page.rows, offset: page.offset)

        loader.load(request: request) { (result) in
            switch result {
            case .success(let response):
                guard let allMessages = response.json as? JSONArray else { return }
                let messages = allMessages.compactMap { Message(from: $0) }
                completion(.success(messages))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func getMessages(of conversation: ConversationID, from date: Date, completion: @escaping (Result<[Message], ChatError>) -> Void) {
        let request = GetLatestMessagesRequest(conversationID: conversation, fromDate: date)

        loader.load(request: request) { (result) in
            switch result {
            case .success(let response):
                guard let allMessages = response.json as? JSONArray else { return }
                let messages = allMessages.compactMap { Message(from: $0) }
                completion(.success(messages))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func send(message: MessageToSend, to conversation: ConversationID, completion: @escaping (Result<Void, ChatError>) -> Void) {
        let request = SendMessagesRequest(conversationID: conversation, message: message)

        loader.load(request: request) { (result) in
            switch result {
            case .success: completion(.success(()))
            case .failure: completion(.failure(.unknown))
            }
        }
    }

    func upload(file: FileToUpload, progress: ((Float) -> Void)?, completion: @escaping (Result<UploadedFile, ChatError>) -> Void) {
        let request = SingleFileUploadRequest(fileName: file.fileName, fileData: file.fileData, mimeType: file.mimeType)

        loader.upload(request: request, progress: progress) { (result) in
            switch result {
            case .success(let response):
                guard let aFile = response.json as? JSONObject else { return }
                guard var uploadedFile = UploadedFile(from: aFile) else { return }
                uploadedFile.refID = file.id
                completion(.success(uploadedFile))
            case .failure:
                completion(.failure(.unknown))
            }
        }
    }

    func createContact(with email: String, in conversation: ConversationID?, completion: @escaping (Result<Void, ChatError>) -> Void) {
        let request = CreateContactRequest(email: email, conversationID: conversation)

        loader.load(request: request) { (result) in
            switch result {
            case .success: completion(.success(()))
            case .failure: completion(.failure(.unknown))
            }
        }
    }
}
