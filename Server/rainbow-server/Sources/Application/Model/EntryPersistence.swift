//
//  EntryPersistence.swift
//  Application
//
//  Created by David Okun IBM on 5/2/18.
//

import Foundation
import CouchDB
import SwiftyJSON

enum RainbowPersistenceError: Error {
    case noAvatar
}

extension ScoreEntry {
    class Persistence {
        private static func getDatabase(from client: CouchDBClient, completion: @escaping (_ database: Database?, _ error: Error?) -> Void) {
            client.dbExists("rainbow-entries") { exists, error in
                if exists {
                    completion(Database(connProperties: client.connProperties, dbName: "rainbow-entries"), nil)
                } else {
                    client.createDB("rainbow-entries", callback: { database, error in
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
                database.create(updatedCopy, callback: { id, _, _, error in
                    completion(id, error)
                })
            }
        }
        
        // Update document        
        static func update(id: String, entry: ScoreEntry, to client: CouchDBClient, completion: @escaping (_ entryID: String?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                var entryCopy = entry
                guard let updatedCopy = entryCopy.toJSONDocument() else {
                    return completion(nil, RainbowPersistenceError.noAvatar)
                }
                
                database.retrieve(id, callback: { document, error in
                    guard let document = document else {
                        return completion(nil, error)
                    }
                    
                    database.update(id, rev: document["_rev"].stringValue, document: updatedCopy, callback: { rev, _, error in
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
                    return completion(ScoreEntry(document: document, _id: document["_id"].stringValue), nil)
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
                        if let newEntry = ScoreEntry(document: document["doc"], _id: document["doc"]["_id"].stringValue) {
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
        
        static func getScores(from client: CouchDBClient, completion: @escaping (_ entries: [ScoreEntry]?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    return completion(nil, error)
                }
                
                database.queryByView("leader-board", ofDesign: "LeaderBoard", usingParameters: [Database.QueryParameters.descending(true)], callback: { (documents, error) in
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
