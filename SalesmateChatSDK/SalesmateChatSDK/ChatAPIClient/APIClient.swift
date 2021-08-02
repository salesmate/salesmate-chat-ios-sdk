//
//  APIClient.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation
@_implementationOnly import HTTP

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

    func getAuthToken(completion: @escaping (Result<(pseudoName: String, authToken: String, channels: [String]), ChatError>) -> Void) {
        let request = GetSCAuthTokenRequest()

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
}
