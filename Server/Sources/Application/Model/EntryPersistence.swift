//
//  EntryPersistence.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import CouchDB
import SwiftyJSON
import Dispatch

enum RainbowPersistenceError: Error {
    case noAvatar
}

extension ScoreEntry {
    class Persistence {
        private static func getDatabase(from client: CouchDBClient, completion: @escaping (_ database: Database?, _ error: Error?) -> Void) {
            client.dbExists("watsonml-entries") { exists, error in
                if exists {
                    completion(Database(connProperties: client.connProperties, dbName: "watsonml-entries"), nil)
                } else {
                    client.createDB("watsonml-entries", callback: { database, error in
                        completion(database, error)
                    })
                }
            }
        }
        
        static func save(entry: ScoreEntry, to client: CouchDBClient, completion: @escaping (_ entryID: String?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                var entryCopy = entry
                guard let updatedCopy = entryCopy.toJSONDocument() else {
                    return completion(nil, RainbowPersistenceError.noAvatar)
                }
                database.create(updatedCopy, callback: { identifier, _, _, error in
                    completion(identifier, error)
                })
            }
        }
        
        // Update document        
        static func update(identifier: String, entry: ScoreEntry, to client: CouchDBClient, completion: @escaping (_ entryID: String?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                
                database.retrieve(identifier, callback: { document, error in
                    guard let document = document else {
                        return completion(nil, error)
                    }
                    
                    var entryCopy = entry
                    entryCopy.avatarImage = Data(base64Encoded: document["avatarImage"].stringValue, options: .ignoreUnknownCharacters)
                    
                    guard let updatedCopy = entryCopy.toJSONDocument() else {
                        return completion(nil, RainbowPersistenceError.noAvatar)
                    }
                    
                    database.update(identifier, rev: document["_rev"].stringValue, document: updatedCopy, callback: { rev, _, error in
                        completion(rev, error)
                    })
               })
            }
        }
        
        static func get(from client: CouchDBClient, with entryID: String, completion: @escaping (_ entry: ScoreEntry?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                database.retrieve(entryID, callback: { document, error in
                    guard let document = document else {
                        return completion(nil, error)
                    }
                    return completion(ScoreEntry(document: document, entryId: document["_id"].stringValue), nil)
                })
            }
        }
        
        static func getAll(from client: CouchDBClient, completion: @escaping (_ entries: [ScoreEntry]?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                database.retrieveAll(includeDocuments: true, callback: { documents, retrieveError in
                    guard let documents = documents else {
                        return completion(nil, retrieveError)
                    }
                    var entries = [ScoreEntry]()
                    for document in documents["rows"].arrayValue {
                        if let newEntry = ScoreEntry(document: document["doc"], entryId: document["doc"]["_id"].stringValue) {
                            entries.append(newEntry)
                        }
                    }
                    completion(entries, nil)
                })
            }
        }
        
        static func getLeaderBoardData(from client: CouchDBClient, completion: @escaping (_ entries: [ScoreEntry]?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }                                
                
                database.queryByView("leader-board", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.descending(false)], callback: { (documents, error) in
                    guard let documents = documents else {
                        return completion(nil, error)
                    }
                    var entries = [ScoreEntry]()
                    for document in documents["rows"].arrayValue {
                        if let newEntry = ScoreEntry(document: document["value"]) {
                            entries.append(newEntry)
                        }
                    }
                    completion(entries, nil)
                })
                
            }
        }
        
        static func getLeaderBoardDataForUser(id: String, from client: CouchDBClient, completion: @escaping (_ entries: [ScoreEntry]?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                let dispatchGroup = DispatchGroup()
                var entries = [ScoreEntry]()
                
                dispatchGroup.enter()
                database.retrieve(id, callback: { document, error in
                    if let document = document, let newEntry = ScoreEntry(document: document)  {
                        if newEntry.finishDate != nil {
                            entries.append(newEntry)
                        }
                    }
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                database.queryByView("leader-board", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.limit(10) ,Database.QueryParameters.descending(false), Database.QueryParameters.reduce(false)], callback: { documents, error in
                    if let documents = documents {
                        for document in documents["rows"].arrayValue {
                            if let newEntry = ScoreEntry(document: document["value"]) {
                                entries.append(newEntry)
                            }
                        }
                    }
                    dispatchGroup.leave()
                })
                dispatchGroup.notify(queue: DispatchQueue.global(qos: .default), execute: {
                    let uniqueEntries = Array(Set(entries))
                    let sortedEntries = uniqueEntries.sorted {
                        guard let first = $0.totalTime, let second = $1.totalTime else {
                            return false
                        }
                        return first < second
                    }
                    completion(sortedEntries, nil)
                })
            }
        }
        
        
        static func getUserCounts(from client: CouchDBClient, completion: @escaping (_ entries: UserCount?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                let dispatchGroup = DispatchGroup()
                var totalUserCount: Int = 0
                var totalUserCountCompletingGame: Int = 0
                
                dispatchGroup.enter()
                database.queryByView("leader-board", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.reduce(true)], callback: { documents, error in
                    if let documents = documents {
                        totalUserCountCompletingGame =  documents["rows"][0]["value"].intValue
                    }
                    dispatchGroup.leave()
                })
                dispatchGroup.enter()
                database.queryByView("totalUserCount", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.reduce(true)], callback: { documents, error in
                    if let documents = documents {
                        totalUserCount =  documents["rows"][0]["value"].intValue
                    }
                    dispatchGroup.leave()
                })
                dispatchGroup.notify(queue: DispatchQueue.global(qos: .default), execute: {
                    let count = UserCount(totalUsers: totalUserCount, totalUsersCompletingGame: totalUserCountCompletingGame)
                    completion(count, nil)
                })
            }
        }
        
        
        static func getScores(from client: CouchDBClient, completion: @escaping (_ entries: [ScoreEntry]?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                
                database.queryByView("leader-board", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.descending(false),Database.QueryParameters.reduce(false)], callback: { (documents, error) in
                    guard let documents = documents else {
                        return completion(nil, error)
                    }
                    var entries = [ScoreEntry]()
                    for document in documents["rows"].arrayValue {
                        if let newEntry = ScoreEntry(timeTaken: document["key"].doubleValue, document: document["value"]) {
                            entries.append(newEntry)
                        }
                    }
                    completion(entries, nil)
                })
                
            }
        }
    
    }
}
