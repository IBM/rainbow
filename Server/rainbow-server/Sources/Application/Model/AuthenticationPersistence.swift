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
        private static func getDatabase(from client: CouchDBClient, completion: @escaping (_ database: Database?, _ error: Error?) -> Void) {
            client.dbExists("routes-users") { exists, error in
                if exists {
                    completion(Database(connProperties: client.connProperties, dbName: "routes-users"), nil)
                } else {
                        completion(nil, error)
                }
            }
        }
    
    static func get(from client: CouchDBClient, completion: @escaping (_ entry: Authentication?, _ error: Error?) -> Void) {
            getDatabase(from: client) { database, error in
                guard let database = database else {
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
                    print(docArr[0]["doc"])
                    return completion(Authentication(document: docArr[0]["doc"]), nil)
                })
            }
        }
    }
}
