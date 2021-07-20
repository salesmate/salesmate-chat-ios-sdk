//
//  IntegerID.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 05/04/21.
//

import Foundation

/// Numeric ID can be string or Int. So we have created this structure to handle both cases.
struct IntegerID {
    private let value: String
}

extension IntegerID: ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self.value = String(value)
    }
}

extension IntegerID: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        self.value = value
    }
}

extension IntegerID: LosslessStringConvertible {
    init?(_ description: String) {
        self.value = description
    }
    
    var description: String {
        value
    }
}

extension IntegerID: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = String(intValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "UserID must be Either String or Int.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension IntegerID: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value
    }
    
    static func == (lhs: Self, rhs: String) -> Bool {
        lhs.value == rhs
    }
    
    static func == (lhs: Self, rhs: Int) -> Bool {
        lhs.value == String(rhs)
    }
}
