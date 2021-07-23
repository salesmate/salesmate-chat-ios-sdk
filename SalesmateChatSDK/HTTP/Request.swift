//
//  Request.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

public protocol EndPoint {
    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: HTTPHeaders? { get }
    var body: HTTPBody? { get }
}

public protocol HTTPRequest: EndPoint {
    var request: URLRequest? { get }
}

extension HTTPRequest {
    var queryItems: [URLQueryItem]? { nil }
    var headers: HTTPHeaders? { nil }
    var body: HTTPBody? { nil }
    
    var request: URLRequest? {
        // Construct URL
        var components = URLComponents(string: path)
        components?.path = path
        components?.queryItems = queryItems?.filter({ !($0.value?.isEmpty ?? true) }) // Remove nil or Empty value.
        
        guard let requestURL = components?.url else {
            print("Can not generate URL")
            return nil
        }
        
        var request = URLRequest(url: requestURL,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: 30.0)
        
        request.httpMethod = method.rawValue
        
        // Add headers from all source.
        var allHeaders: HTTPHeaders = [:]
        
        allHeaders.merge(headers ?? [:], uniquingKeysWith: { $1 })
        allHeaders.merge(body?.headers ?? [:], uniquingKeysWith: { $1 })
        
        allHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        // Set body if applicable.
        request.httpBody = try? body?.encode()
        
        return request
    }
}

extension URLRequest {
    
    public var curl: String {
        guard let url = url else { return "" }
        
        var baseCommand = #"curl "\#(url.absoluteString)""#
        
        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        
        var command = [baseCommand]
        
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }
        
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        
        return command.joined(separator: " \\\n\t")
    }
}
