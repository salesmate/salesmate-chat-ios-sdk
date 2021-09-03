//
//  DateTime.swift
//  SalesmateChatCore
//
//  Created by Chintan Dave on 25/03/21.
//

import Foundation

extension DateFormatter {
    static let fullISO8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let fullISO8601NoFraction: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options) {
        self.init()
        self.formatOptions = formatOptions
    }

    static let convertor = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    var stringAsISO8601Format: String { ISO8601DateFormatter.convertor.string(from: self) }

    var durationString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var shortDurationString: String {
        let interval = Int(abs(timeIntervalSince(Date())))
        let minute = 60
        let hour = 60 * 60
        let day = hour * 24
        let weak = day * 7
        let month = day * 30
        let year = day * 365

        if interval < minute {
            return "Now"
        } else if interval < hour {
            return "\(interval / minute)m"
        } else if interval < day {
            return "\(interval / hour)h"
        } else if interval < weak {
            return "\(interval / day)d"
        } else if interval < month {
            return "\(interval / weak)w"
        } else if interval < year {
            return "\(interval / month)mth"
        } else {
            return "\(interval / year)y"
        }
    }
}

extension String {
    var dateFromISO8601Format: Date? { ISO8601DateFormatter.convertor.date(from: self) }
}
