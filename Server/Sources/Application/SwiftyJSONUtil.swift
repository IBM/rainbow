//
//  SwiftyJSONUtil.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import SwiftyJSON
import LoggerAPI

class Formatter {
    private static var internalJsonDateTimeFormatter: DateFormatter?
    
    static var jsonDateTimeFormatter: DateFormatter {
        if internalJsonDateTimeFormatter == nil {
            internalJsonDateTimeFormatter = DateFormatter()
            internalJsonDateTimeFormatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        }
        return internalJsonDateTimeFormatter!
    }
}

// MARK: - String iso8601
extension String {
    public var iso8601: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter.date(from: self)
    }
}

extension Date {
    public var iso8601String: String? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter.string(from: self)
    }
}

// MARK: - JSON dateTime
extension JSON {
    public var dateTime: Date? {
        Log.debug("Converting JSON to datetime object")
        switch type {
        case .string:
            Log.debug("Detected string: \(self.stringValue)")
            return Formatter.jsonDateTimeFormatter.date(from: self.stringValue)
        case .number:
            Log.debug("Detected number: \(String(describing: self.doubleValue))")
            return Date(timeIntervalSinceReferenceDate: self.doubleValue)
        default:
            return nil
        }
    }
}
