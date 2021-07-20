//
//  Method.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

typealias HTTPHeaders = [String: String]
typealias JSONObject = [String: Any]
typealias JSONArray = [JSONObject]
