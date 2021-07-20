//
//  APIRequestLoader.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 06/05/21.
//

import Foundation

class APIRequestLoader: NSObject {
    private lazy var session: URLSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private lazy var progressHandlers: [Int: ProgressHandler] = [:]
}

extension APIRequestLoader: RequestLoader {
    
    func load(request: HTTPRequest, completion: @escaping (HTTPResult) -> Void) {
        guard let requestToAPI = request.request else { return }
        
        print("******** Chat Request curl *******")
        print(requestToAPI.curl)
        
        let task = session.dataTask(with: requestToAPI, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            completion(HTTPResult(request: request, responseData: data, response: response, error: error))
        })
        
        task.resume()
    }
}

extension APIRequestLoader: RequestUploader {
    
    func upload(request: HTTPRequest, progress: ProgressHandler?, completion: @escaping (HTTPResult) -> Void) {
        guard let requestToAPI = request.request else { return }
        
        let task = session.uploadTask(with: requestToAPI, from: requestToAPI.httpBody) { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            completion(HTTPResult(request: request, responseData: data, response: response, error: error))
        }
        
        progressHandlers[task.taskIdentifier] = progress
        
        task.resume()
    }
}

extension APIRequestLoader: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let progressHandler = progressHandlers[task.taskIdentifier] else { return }
        
        let progress = (Float(totalBytesSent) / Float(totalBytesExpectedToSend))
        progressHandler(progress)
        
        if progress == 1 {
            progressHandlers.removeValue(forKey: task.taskIdentifier)
        }
    }
}
