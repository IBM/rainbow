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
import Kitura

private var client: CouchDBClient?
private var pushNotification: PushNotification?

func initializeScoreRoutes(app: App) {
    client = app.services.couchDBService
    pushNotification = app.services.pushNotificationService
    
    app.router.post("watsonml/entries", handler: addNewEntry)
    app.router.put("/watsonml/entries", handler: updateEntry)
    app.router.get("/watsonml/leaderboard", handler: getLeaderBoard)
    app.router.get("/watsonml/leaderboard", handler: getLeaderBoardForUser)
    app.router.get("/avatar/leaderboardAvatar/:id", handler: getLeaderboardAvatar)
    app.router.get("/watsonml/user/counts", handler: getUserCounts)
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

func updateEntry(identifier: String, newEntry: ScoreEntry, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    Log.info("Updating entry document")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }

    // update database with new entry
    ScoreEntry.Persistence.update(identifier: identifier, entry: newEntry, to: client) { revID, error in
        guard let revID = revID else {
            return completion(nil, .noContent)
        }
        Log.info("Document updated with new revision: ", functionName: revID)
        ScoreEntry.Persistence.get(from: client, with: identifier, completion: { entry, error in
            // logic for push notification. If the update is for game completion
            // check to see if notification has to be sent.
            
            guard let entry = entry else {
                return completion(nil, error as? RequestError)
            }
            
            if entry.finishDate != nil {
                /// the user finished a game
                guard let pushNotification = pushNotification else {
                    Log.error("Push Notification not initialized.")
                    return completion(entry, error as? RequestError)
                }
                
                /// call push notification service
                Log.info("Sending push notification")
                DispatchQueue.global(qos: .background).async {
                    pushNotification.sendNotification(scoreEntry: entry)
                }
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

func getLeaderBoardForUser(id: String, completion: @escaping ([ScoreEntry]?, RequestError?) -> Void) {
    Log.info("Getting leaderboard data")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.getLeaderBoardDataForUser(id: id, from: client) { entries, error in
        return completion(entries, error as? RequestError)
    }
}

func getUserCounts(completion: @escaping (UserCount?, RequestError?) -> Void) {
    Log.info("Getting user counts for dashboard")
    guard let client = client else {
        return completion(nil, .failedDependency)
    }
    ScoreEntry.Persistence.getUserCounts( from: client) { userCounts, error in
        return completion(userCounts, error as? RequestError)
    }
}

func getLeaderboardAvatar(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
    guard let requestID = request.parameters["id"] else {
        response.status(.badRequest).send(json: [])
        return
    }
    guard let cloudantID = requestID.components(separatedBy: ".").first else {
        response.status(.badRequest).send(json: [])
        return
    }
    Log.info("Retrieving avatar for id: \(cloudantID)")
    ScoreEntryAvatar.getImage(with: cloudantID) { imageData, error in
        guard let imageData = imageData else {
            response.status(.preconditionFailed).send(json: ["Error": "No Image Data Available"])
            return
        }
        response.status(.OK).send(data: imageData)
    }
}
