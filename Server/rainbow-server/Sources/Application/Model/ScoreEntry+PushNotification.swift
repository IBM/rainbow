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
        let doc: JSON = document["doc"]
        id = doc["_id"].stringValue
        deviceIdentifier = doc["deviceIdentifier"].stringValue
        username = doc["username"].stringValue
        totalTime = timeTaken
        avatarURL = nil
        avatarImage = nil
        startDate = nil
        finishDate = nil
        objects = [ObjectEntry]()
    }
}
