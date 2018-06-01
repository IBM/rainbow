//
//  Date+WatsonML.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

extension Date {
    var vivaFormatted: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: self)
    }
    
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    static let watson: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter
    }()
}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
    
    var dateFromWatson: Date? {
        return Formatter.watson.date(from: self)
    }
}
