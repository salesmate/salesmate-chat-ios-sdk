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

struct FORMBody: HTTPBody {
    var headers: HTTPHeaders = [
        "Content-Type": "application/x-www-form-urlencoded"
    ]

    private let value: [String : String]
    init(params: [String: String]) {
        self.value = params
    }

    func encode() throws -> Data {
        var data = Data()

        let parameterArray = value.map { (arg) -> String in
          let (key, value) = arg
            if key != "user_details" {
                return "\(key)=\(self.percentEscapeString(value))"
            }
           return "\(key)=\(value)"
        }
        data =  parameterArray.joined(separator: "&").data(using: String.Encoding.utf8) ?? Data()
        return data
    }
    
    private func percentEscapeString(_ string: String) -> String {
      var characterSet = CharacterSet.alphanumerics
      characterSet.insert(charactersIn: "-._* ")
      
      return string
        .addingPercentEncoding(withAllowedCharacters: characterSet)!
        .replacingOccurrences(of: " ", with: "+")
        .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
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
