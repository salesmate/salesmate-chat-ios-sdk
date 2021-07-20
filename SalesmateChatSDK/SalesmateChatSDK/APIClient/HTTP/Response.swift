//
//  Response.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

struct HTTPResponse {
    let request: HTTPRequest
    let response: HTTPURLResponse
    let body: Data?
}

extension HTTPResponse {
    var json: Any? {
        guard let data = body else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }
}
