//
//  ScoreEntry+PushNotification.swift
//  Application
//
//  Created by Sanjeev Ghimire on 5/9/18.
//
import Foundation
import SwiftyJSON

extension ScoreEntry {
    init?(timeTaken: Double, document: JSON) {
        id = document["id"].stringValue
        deviceIdentifier = document["deviceIdentifier"].stringValue
        username = document["username"].stringValue
        totalTime = timeTaken        
        avatarImage = nil
        startDate = nil
        finishDate = nil
        objects = [ObjectEntry]()
    }
}
