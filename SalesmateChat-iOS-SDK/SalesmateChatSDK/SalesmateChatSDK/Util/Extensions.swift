//
//  Extensions.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 04/04/21.
//

import Foundation
import UIKit

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
        let downloadTask = URLSession.shared.downloadTask(with: self) { urlOrNil, _, errorOrNil in
            guard let fileURL = urlOrNil else {
                if let error = errorOrNil {
                    completion(.failure(error))
                }
                return
            }

            do {
                let savedURL = try FileManager.default.getURLInCachesDirectory(for: lastPathComponent)
                try? FileManager.default.removeItem(at: savedURL)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                completion(.success(savedURL))
            } catch {
                print(error)
                completion(.failure(error))
            }
        }
        downloadTask.resume()
    }
}

extension FileManager {

    func getURLInCachesDirectory(for fileName: String) throws -> URL {
        let documentsURL = try url(for: .cachesDirectory,
                                   in: .userDomainMask,
                                   appropriateFor: nil,
                                   create: true)
        return documentsURL.appendingPathComponent(fileName)
    }
}


extension Date{
    func getDayWithTimezone(timeZone:TimeZone?) -> String{
        var calendar = Calendar(identifier: .gregorian)
        if timeZone != nil{
            calendar.timeZone = timeZone!;
        }
        let dateComponents = calendar.dateComponents([.weekday], from: self)
        let weekDay = dateComponents.weekday ?? 1;
        let weekDayName = DateFormatter().weekdaySymbols[weekDay-1];
        return weekDayName;
    }
    
    func getTimeIntervalSinceMidnightWithTimezone(timeZone:TimeZone?) -> TimeInterval{
        return self.getStartOfDay(timeZone: timeZone).timeIntervalSinceNow
    }
    
    func getStartOfDay(timeZone:TimeZone?) -> Date{
        var cal = Calendar(identifier: .gregorian)
        if timeZone != nil{
            cal.timeZone = timeZone!;
        }
        let newDate = cal.startOfDay(for: self);
        return newDate;
    }
}
extension UIApplication {
    
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
