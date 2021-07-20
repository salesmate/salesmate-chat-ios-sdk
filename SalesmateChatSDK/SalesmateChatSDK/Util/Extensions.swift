//
//  Extensions.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 04/04/21.
//

import Foundation

extension Set {
    
    mutating func update<Source>(_ sequence: Source) where Element == Source.Element, Source : Sequence {
        sequence.forEach { self.update(with: $0) }
    }
}

extension Data {
    var utf8: String? { String(data: self, encoding: .utf8) }
}

func run(afterDelay seconds: TimeInterval, execute work: @escaping @convention(block) () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
}
