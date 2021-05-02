//
//  ScoreEntry+Client.swift
//  rainbow
//
//  Created by David Okun IBM on 5/8/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    var isDebugMode: Bool {
        let dictionary = ProcessInfo.processInfo.environment
        return dictionary["DEBUGMODE"] != nil
    }
    
    var rainbowServerBaseURL: String {
        var baseURL = UIApplication.shared.isDebugMode ? "http://localhost:8080" : "https://rainbow-scavenger-viz-rec.mybluemix.net" // need to update when we deploy
        baseURL = "https://rainbow-scavenger-viz-rec.mybluemix.net"
        return baseURL
    }
}

enum RainbowClientError: Error {
    case couldNotCreateClient
    case couldNotAddNewEntry
    case couldNotGetEntries
    case couldNotLoadImage
    case couldNotUpdateEntry
    case couldNotGetPlayerCount
}

struct ImageResponseField: Codable {
    var avatarImage: String
}

struct ImageResponseRow: Codable {
    var fields: ImageResponseField
}

struct ImageResponse: Codable {
    var rows: [ImageResponseRow]
}

extension ScoreEntry {
    class ServerCalls {
        static func save(entry: ScoreEntry, completion: @escaping (_ entry: ScoreEntry?, _ error: RainbowClientError?) -> Void) {
            guard let client = KituraKit(baseURL: UIApplication.shared.rainbowServerBaseURL) else {
                return completion(nil, RainbowClientError.couldNotCreateClient)
            }
            client.post("/watsonml/entries", data: entry) { (savedEntry: ScoreEntry?, error: RequestError?) in
                if error != nil {
                    return completion(nil, RainbowClientError.couldNotAddNewEntry)
                } else {
                    return completion(savedEntry, nil)
                }
            }
        }
        
        static func update(entry: ScoreEntry, completion: @escaping (_ entry: ScoreEntry?, _ error: RainbowClientError?) -> Void) {
            guard let client = KituraKit(baseURL: UIApplication.shared.rainbowServerBaseURL) else {
                return completion(nil, RainbowClientError.couldNotCreateClient)
            }            
            guard let identifier = entry.id else {
                return completion(nil, RainbowClientError.couldNotUpdateEntry)
            }
            client.put("/watsonml/entries", identifier: identifier, data: entry) { (savedEntry: ScoreEntry?, error: RequestError?) in
                if error != nil {
                    return completion(nil, RainbowClientError.couldNotUpdateEntry)
                } else {
                    return completion(savedEntry, nil)
                }
            }
        }
        
        static func getCount(completion: @escaping (_ count: UserCount?, _ error: RainbowClientError?) -> Void) {
            guard let client = KituraKit(baseURL: UIApplication.shared.rainbowServerBaseURL) else {
                return completion(nil, RainbowClientError.couldNotCreateClient)
            }
            client.get("/watsonml/user/counts") { (count: UserCount?, error: RequestError?) in
                if error != nil {
                    return completion(nil, RainbowClientError.couldNotGetPlayerCount)
                } else {
                    return completion(count, nil)
                }
            }
        }
        
        static func getAll(for identifier: String?, completion: @escaping (_ entries: [ScoreEntry]?, _ error: RainbowClientError?) -> Void) {
            guard let client = KituraKit(baseURL: UIApplication.shared.rainbowServerBaseURL) else {
                return completion(nil, RainbowClientError.couldNotCreateClient)
            }
            if let identifier = identifier {
                client.get("/watsonml/leaderboard", identifier: identifier) { (entries: [ScoreEntry]?, error: RequestError?) in
                    if error != nil {
                        print("leaderboard error: \(error.debugDescription)")
                        return completion(nil, RainbowClientError.couldNotGetEntries)
                    } else {
                        return completion(entries, nil)
                    }
                }
            } else {
                client.get("/watsonml/leaderboard") { (entries: [ScoreEntry]?, error: RequestError?) in
                    if error != nil {
                        return completion(nil, RainbowClientError.couldNotGetEntries)
                    } else {
                        return completion(entries, nil)
                    }
                }
            }
        }
    }
}
