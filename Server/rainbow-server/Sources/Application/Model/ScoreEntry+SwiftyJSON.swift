//
//  ScoreEntry+SwiftyJSON.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import SwiftyJSON

extension ScoreEntry {
    init?(document: JSON) {
        anonymousIdentifier = document["_id"].stringValue
        username = document["username"].stringValue
        avatarURL = document["avatarURL"].stringValue
        guard let potentialStartDate = document["startDate"].dateTime else {
            return nil
        }
        startDate = potentialStartDate
        finishDate = document["finishDate"].dateTime
        var objectEntries = [ObjectEntry]()
        for object in document["objects"].arrayValue {
            let name = object["name"].stringValue
            guard let timestamp = object["timestamp"].dateTime else {
                continue
            }
            objectEntries.append(ObjectEntry(name: name, timestamp: timestamp))
        }
        objects = objectEntries
    }
    
    func toJSONDocument() -> JSON {
        let encoded = try! JSONEncoder().encode(self)
        return JSON(data: encoded)
    }
}
