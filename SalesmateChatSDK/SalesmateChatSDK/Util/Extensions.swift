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

extension URL {

    func downloadAndSave(completion: @escaping (Result<URL, Error>) -> Void) {
        let downloadTask = URLSession.shared.downloadTask(with: self) {
            urlOrNil, _, errorOrNil in
            guard let fileURL = urlOrNil else {
                if let error = errorOrNil {
                    completion(.failure(error))
                }
                return
            }

            do {
                let documentsURL = try
                    FileManager.default.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true)
                let savedURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                completion(.success(savedURL))
            } catch {
                completion(.failure(error))
            }
        }

        downloadTask.resume()
    }
}
