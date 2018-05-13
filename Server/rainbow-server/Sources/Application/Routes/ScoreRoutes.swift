//
//  ScoreRoutes.swift
//  Application
//
//  Created by David Okun IBM on 5/1/18.
//

import Foundation
import CouchDB
import LoggerAPI
import KituraContracts

private var client: CouchDBClient?
private var pushNotification: PushNotification?

func initializeScoreRoutes(app: App) {
    client = app.services.couchDBService
    pushNotification = app.services.pushNotificationService
    
    app.router.get("/entries", handler: getAllEntries)
    app.router.get("/entries", handler: getOneEntry)
    app.router.post("/entries", handler: addNewEntry)
    app.router.put("/entries", handler: updateEntry)
    app.router.get("/leaderboard", handler: getLeaderBoard)
}

func getAllEntries(completion: @escaping ([ScoreEntry]?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.getAll(from: client) { entries, error in
        return completion(entries, error as? RequestError)
    }
}

func getOneEntry(id: String, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.get(from: client, with: id) { entry, error in
        return completion(entry, error as? RequestError)
    }
}

func addNewEntry(newEntry: ScoreEntry, completion: @escaping(ScoreEntry?, RequestError?) -> Void) {
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.save(entry: newEntry, to: client) { entryID, error in
        guard let entryID = entryID else {
            return completion(nil, .noContent)
        }
        ScoreEntry.Persistence.get(from: client, with: entryID, completion: { entry, error in
            return completion(entry, error as? RequestError)
        })
    }
}

func updateEntry(id: String,newEntry: ScoreEntry, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    Log.info("Updating entry document")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }

    // update database with new entry
    ScoreEntry.Persistence.update(id: id, entry: newEntry, to: client) { revID, error in
        guard let revID = revID else {
            return completion(nil, .noContent)
        }
        Log.info("Document updated with new revision: ", functionName: revID)
        ScoreEntry.Persistence.get(from: client, with: id, completion: { entry, error in
            // logic for push notification. If the update is for game completion
            // check to see if notification has to be sent.
            
            if entry?.finishDate != nil {
                /// the user finished a game
                /// call push notification service
                Log.info("Sending push notification")
                pushNotification?.sendNotification(scoreEntry: newEntry)
            }
            return completion(entry, error as? RequestError)
        })
    }
    
}

/// returns sorted list of scores by time taken
func getLeaderBoard(completion: @escaping ([ScoreEntry]?, RequestError?) -> Void) {
    Log.info("Getting leaderboard data")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.getLeaderBoardData(from: client) { entries, error in
        return completion(entries, error as? RequestError)
    }
}
