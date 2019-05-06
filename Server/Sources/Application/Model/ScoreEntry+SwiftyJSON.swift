//
//  ScoreEntry+SwiftyJSON.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import SwiftyJSON

extension ScoreEntry {
    init?(document: JSON, entryId: String) {
        id = entryId
        deviceIdentifier = document["deviceIdentifier"].stringValue
        username = document["username"].stringValue
        startDate = document["startDate"].dateTime
        finishDate = document["finishDate"].dateTime
        avatarImage = nil
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
        avatarImage = getImageData(avatarImageString: document["avatarImage"].stringValue)
    }
    
    private func getImageData(avatarImageString: String) -> Data?{
        guard let imageData = Data(base64Encoded: avatarImageString) else {
            print("Canot conver avatarImage to base64Encoded string")
            return nil
        }
        return imageData
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
        if document["finishDate"] != nil {
            totalTime = document["finishDate"].doubleValue - document["startDate"].doubleValue
        }
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
