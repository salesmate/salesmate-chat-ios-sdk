//
//  Error.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

struct HTTPError: Error {
    
    enum Code: String, Codable {
        case AuthorizationFailed = "AuthorizationFailed"
        case networkFail
        case unknown
    }
    
    /// The high-level classification of this error
    let name: Code
    let message: String?
    
    /// The HTTPRequest that resulted in this error
    let request: HTTPRequest
    
    /// Any HTTPResponse (partial or otherwise) that we might have
    let response: HTTPResponse?
    
    /// If we have more information about the error that caused this, stash it here
    let underlyingError: Error?
}
