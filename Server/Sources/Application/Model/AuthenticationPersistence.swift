//
//  AuthenticationPersistence.swift
//  Application
//
//  Created by Sanjeev Ghimire on 5/14/18.
//

import Foundation
import CouchDB
import LoggerAPI
import SwiftyJSON

extension Authentication {
    class Persistence {
        
    static let databaseName: String = "routes-users"
    
    private static func getDatabase(from client: CouchDBClient, completion: @escaping (_ database: Database?, _ error: Error?) -> Void) {
        client.dbExists(databaseName) { exists, error in
            Log.debug("Database Existence:: \(exists)")
            if exists {
                completion(Database(connProperties: client.connProperties, dbName: databaseName), nil)
            } else {
                Log.error("Error: \(String(describing: error?.localizedDescription))")
                completion(nil, error)
            }
        }
    }
    
    static func get(from client: CouchDBClient, completion: @escaping (_ entry: Authentication?, _ error: Error?) -> Void) {
        Log.debug("Getting authentication creds")
            getDatabase(from: client) { database, error in
                guard let database = database else {
                    Log.error("No  database found")
                    return completion(nil, error)
                }
                database.retrieveAll(includeDocuments: true, callback: { documents, _ in
                    guard let documents = documents else {
                        return completion(nil, error)
                    }
                    if documents["rows"].arrayValue.count > 1 {
                        return completion(nil, error)
                    }                    
                    let docArr = documents["rows"].arrayValue
                    Log.debug(docArr[0]["doc"].stringValue)
                    return completion(Authentication(document: docArr[0]["doc"]), nil)
                })
            }
        }
    }
}
