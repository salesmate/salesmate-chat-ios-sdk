//
//  Miscellaneous.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 01/07/21.
//  Copyright © 2021 RapidOps Solution Private Limited. All rights reserved.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    //guard enableLog else { return }
    
    #if DEBUG
    items.forEach { Swift.print($0, separator: separator, terminator: terminator) }
    #endif
}

func run(afterDelay seconds: TimeInterval, execute work: @escaping @convention(block) () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
}
