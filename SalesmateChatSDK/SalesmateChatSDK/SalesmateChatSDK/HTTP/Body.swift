//
//  Body.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

protocol HTTPBody {
    var headers: HTTPHeaders { get }

    func encode() throws -> Data
}

struct JSONBody<T: Encodable>: HTTPBody {
    var headers: HTTPHeaders = [
        "Content-Type": "application/json; charset=utf-8"
    ]

    private let value: T

    init(_ value: T) {
        self.value = value
    }

    func encode() throws -> Data {
        try JSONEncoder().encode(value)
    }
}

struct MultipartSingleFileBody: HTTPBody {
    var headers: HTTPHeaders {
        ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
    }

    private let boundary = Self.createBoundary()
    private let fileName: String
    private let fileData: Data
    private let mimeType: String

    init(fileName: String, fileData: Data, mimeType: String) {
        self.fileName = fileName
        self.fileData = fileData
        self.mimeType = mimeType
    }

    private static func createBoundary() -> String {
      var uuid = UUID().uuidString
      uuid = uuid.replacingOccurrences(of: "-", with: "")
      uuid = uuid.map { $0.lowercased() }.joined()

      let boundary = String(repeating: "-", count: 20) + uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"

      return boundary
    }

    func encode() throws -> Data {
        var data = Data()

        data.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) ?? Data())
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) ?? Data())
        data.append(fileData)
        data.append("\r\n".data(using: .utf8) ?? Data())
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())

        return data
    }
}
