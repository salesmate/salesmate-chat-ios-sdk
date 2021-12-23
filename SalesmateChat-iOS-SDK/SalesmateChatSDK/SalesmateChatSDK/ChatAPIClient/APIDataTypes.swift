//
//  DataTypes.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 19/07/21.
//

import Foundation
@_implementationOnly import SwiftyJSON

struct HeaderKey {
    static let linkName = "x-linkname"
    static let workspaceID = "x-workspace-id"
    static let contactID = "x-contact-id"
    static let uniqueID = "x-unique-id"
    static let verifiedID = "x-verified-id"
    static let contentType = "Content-Type"
}

struct LoginFormHeaderKey {
    static let tenantId = "tenant_id"
    static let deviceId = "device_id"
    static let visitorId = "visitor_id"
    static let sessionId = "session_id"
    static let sdkName = "sdk_name"
    static let uuid = "uuid"
    static let appKey = "app_key"
    static let hour = "hour"
    static let timestamp = "timestamp"
    static let userDetails = "user_details"
}

struct ResponseKeyValue {
    static let status = "Status"
    static let success = "success"
    static let failure = "failure"
    static let error = "Error"
    static let name = "name"
    static let message = "message"
    static let data = "Data"
}

struct Page {
    let size: Int
    private(set) var page: Int = 0

    var offset: Int { page * size}
    var rows: Int { size }

    init(size: Int = 20) {
        self.size = size
    }

    @discardableResult
    mutating func next() -> Self {
        page += 1
        return self
    }

    @discardableResult
    mutating func reset() -> Self {
        page = 0
        return self
    }
}

extension HTTPResult {

    init(request: HTTPRequest, responseData: Data?, response: URLResponse?, error: Error?) {
        if let e = error as? URLError {
            self = .failure(HTTPError(name: .networkFail, message: "", request: request, response: nil, underlyingError: e))
            return
        }

        guard let response = response as? HTTPURLResponse else {
            self = .failure(HTTPError(name: .unknown, message: "", request: request, response: nil, underlyingError: error))
            return
        }

        let httpResponse = HTTPResponse(request: request, response: response, body: responseData ?? Data())

        guard let json = httpResponse.json as? JSONObject else {
            self = .failure(HTTPError(name: .unknown, message: "", request: request, response: httpResponse, underlyingError: error))
            return
        }

        guard let status = json[ResponseKeyValue.status] as? String else {
            self = .failure(HTTPError(name: .unknown, message: "", request: request, response: httpResponse, underlyingError: error))
            return
        }

        if status == ResponseKeyValue.success {
            let data: Data? = {
                guard let object = json[ResponseKeyValue.data] else { return nil }

                if JSONSerialization.isValidJSONObject(object) {
                    return try? JSONSerialization.data(withJSONObject: object, options: [])
                } else if let string = object as? String {
                    return string.data(using: .utf8)
                } else {
                    return nil
                }
            }()
            
            debugPrint("Response Json:\(String(data: data!, encoding: .utf8))");

            if let data = data {
                self = .success(HTTPResponse(request: request, response: response, body: data))
            } else {
                self = .success(httpResponse)
            }
        } else if status == ResponseKeyValue.failure {
            guard let errroObject = json[ResponseKeyValue.error] as? JSONObject,
            let errroCode = errroObject[ResponseKeyValue.name] as? String,
            let apiErrorCode = HTTPError.Code.init(rawValue: errroCode),
            let errroMessage = errroObject[ResponseKeyValue.message] as? String else {
                self = .failure(HTTPError(name: .unknown, message: "", request: request, response: httpResponse, underlyingError: error))
                return
            }

            self = .failure(HTTPError(name: apiErrorCode, message: errroMessage, request: request, response: httpResponse, underlyingError: error))
        } else {
            self = .failure(HTTPError(name: .unknown, message: "", request: request, response: httpResponse, underlyingError: error))
        }
    }
}
