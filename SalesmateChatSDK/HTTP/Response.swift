//
//  Response.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

public struct HTTPResponse {
    let request: HTTPRequest
    let response: HTTPURLResponse
    let body: Data?
    
    public init(request: HTTPRequest, response: HTTPURLResponse, body: Data?) {
        self.request = request
        self.response = response
        self.body = body
    }
}

extension HTTPResponse {
    public var json: Any? {
        guard let data = body else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
}
