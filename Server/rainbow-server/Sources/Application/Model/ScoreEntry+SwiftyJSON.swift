//
//  ScoreEntry+SwiftyJSON.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import SwiftyJSON

extension ScoreEntry {
    init?(document: JSON, _id: String) {
        id = _id
        deviceIdentifier = document["deviceIdentifier"].stringValue
        username = document["username"].stringValue
        startDate = document["startDate"].dateTime
        avatarImage = nil        
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
        totalTime = nil
    }
    
    init?(document: JSON) {
        id = document["id"].stringValue
        deviceIdentifier = nil
        username = document["username"].stringValue
        guard let potentialStartDate = document["startDate"].dateTime else {
            return nil
        }
        avatarImage = nil
        startDate = potentialStartDate
        finishDate = document["finishDate"].dateTime
        objects = nil
        totalTime = nil
    }
    

    mutating func toJSONDocument() -> JSON? {        
        do {
            let encoded = try JSONEncoder().encode(self)
            return JSON(data: encoded)
        } catch {
            return nil
        }
    }
}
