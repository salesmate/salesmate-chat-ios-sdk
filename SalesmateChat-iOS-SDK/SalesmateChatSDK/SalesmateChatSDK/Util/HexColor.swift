//
//  HexColor.swift
//  SalesmateChatSDK
//
//  Created by Chintan Dave on 03/08/21.
//

import Foundation

struct HexColor {
    let value: String
}

extension HexColor: ExpressibleByStringLiteral {

    init(stringLiteral value: StringLiteralType) {
        self.value = value
    }
}

extension HexColor: LosslessStringConvertible {

    init?(_ description: String) {
        self.value = description
    }

    var description: String { value }
}

extension HexColor: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid hex value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
