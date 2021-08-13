//
//  Extensions.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 04/04/21.
//

import Foundation

extension Set {

    mutating func update<Source>(with sequence: Source) where Element == Source.Element, Source: Sequence {
        sequence.forEach { self.update(with: $0) }
    }
}

extension Data {
    var utf8: String? { String(data: self, encoding: .utf8) }
}

extension String {

    func trim() -> String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension UUID {
    static var new: String { UUID().uuidString.lowercased() }
}
