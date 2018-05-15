//
//  GameTimer.swift
//  rainbow
//
//  Created by David Okun IBM on 5/13/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

class GameTimer {
    static func getTimeElapsedString(for entry: ScoreEntry?) -> String {
        guard let interval = entry?.startDate?.timeIntervalSinceNow else {
            return "TimeElapsed\n00:00"
        }
        let totalInterval = interval * -1
        let hoursDiv: div_t = div(Int32(totalInterval), 3600)
        let hours: Int = Int(hoursDiv.quot)
        let minutesDiv: div_t = div(hoursDiv.rem, 60)
        let minutes: Int = Int(minutesDiv.quot)
        let seconds = Int(minutesDiv.rem)
        var hoursString = "", minutesString = "", secondsString = ""
        hoursString = hours < 10 ? "0\(hours)" : "\(hours)"
        minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        return "Time Elapsed\n\(hoursString):\(minutesString):\(secondsString)"
    }
    
    static func getTimeFoundString(startDate: Date, objectTimestamp: Date) -> String {
        let interval = startDate.timeIntervalSince(objectTimestamp)
        let totalInterval = interval * -1
        let hoursDiv: div_t = div(Int32(totalInterval), 3600)
        let hours: Int = Int(hoursDiv.quot)
        let minutesDiv: div_t = div(hoursDiv.rem, 60)
        let minutes: Int = Int(minutesDiv.quot)
        let seconds = Int(minutesDiv.rem)
        let secondsString = seconds == 1 ? "\(seconds) second" : "\(seconds) seconds"
        let minutesString = minutes == 1 ? "\(minutes) minute" : "\(minutes) minutes"
        let hoursString = hours == 1 ? "\(hours) hour" : "\(hours) hours"
        if minutes < 1 {
            return secondsString
        } else if hours < 1 {
            return "\(minutesString), \(secondsString)"
        } else {
            return "\(hoursString), \(minutesString)"
        }
    }
}
