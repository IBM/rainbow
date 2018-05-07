//
//  ScoreEntry+SwiftyJSON.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import SwiftyJSON

extension ScoreEntry {
    init?(document: JSON, id: String) {
        anonymousIdentifier = id
        username = document["username"].stringValue
        avatarURL = document["avatarURL"].stringValue
        guard let potentialStartDate = document["startDate"].dateTime else {
            return nil
        }
        avatarImage = nil
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

    mutating func toJSONDocument() -> JSON? {
        guard let avatarImage = self.avatarImage else {
            // we need to discuss how to proceed if there is no avatar - my guess is to bail
            return nil
        }
        self.avatarURL = AvatarObjectStorage.save(image: avatarImage, to: nil)
        self.avatarImage = nil
        do {
            let encoded = try JSONEncoder().encode(self)
            return JSON(data: encoded)
        } catch {
            return nil
        }
    }
}
