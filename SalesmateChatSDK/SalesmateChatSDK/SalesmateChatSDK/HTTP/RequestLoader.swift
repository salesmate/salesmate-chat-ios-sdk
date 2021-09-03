//
//  RequestLoader.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 24/03/21.
//

import Foundation

protocol RequestLoader {
    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void)
}

protocol RequestUploader {
    typealias ProgressHandler = (Float) -> Void

    func upload(request: HTTPRequest, progress: ProgressHandler?, completion: @escaping (HTTPResult) -> Void)
}
