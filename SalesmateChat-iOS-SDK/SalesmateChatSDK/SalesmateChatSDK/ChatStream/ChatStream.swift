//
//  ChatStream.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 27/05/21.
//  Copyright © 2021 RapidOps Solution Private Limited. All rights reserved.
//

import Foundation

protocol ChatStream: AnyObject {
    var isReady: Bool { get }

    func register(observer: AnyObject, for events: [ChatEventToObserve], of conversation: ConversationID?, onEvent: @escaping (ChatEvent) -> Void)
    func connect(completion: @escaping (Result<Void, ChatError>) -> Void)
    func sendTyping(for conversation: String, and uniqueID: String)
}
