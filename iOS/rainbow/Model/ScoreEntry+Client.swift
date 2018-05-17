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
        
        static func getAll(completion: @escaping (_ entries: [ScoreEntry]?, _ error: RainbowClientError?) -> Void) {
            guard let client = KituraKit(baseURL: UIApplication.shared.rainbowServerBaseURL) else {
                return completion(nil, RainbowClientError.couldNotCreateClient)
            }
            client.get("/watsonml/leaderboard") { (entries: [ScoreEntry]?, error: RequestError?) in
                if error != nil {
                    return completion(nil, RainbowClientError.couldNotGetEntries)
                } else {
                    return completion(entries, nil)
                }
            }
        }
        
        static func getImage(with identifier: String?, completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
            guard let identifier = identifier else {
                return completion(nil, nil)
            }
            let request = RestRequest(method: .post, url: "https://241de9e3-46be-4625-a256-76eab61af5da-bluemix.cloudant.com/rainbow-entries/_design/avatarImage/_search/avatarImageIdx", containsSelfSignedCert: false)
            guard let config = KituraServerCredentials.loadedCredentials() else {
                return
            }
            request.credentials = Credentials.basicAuthentication(username: config.cloudant.username, password: config.cloudant.password)
            request.headerParameters = ["Content-Type": "application/json"]
            let bodyString = "{\"q\": \"_id:\(identifier)\"}"
            request.messageBody = bodyString.data(using: .utf8)
            request.responseObject { (response: RestResponse<ImageResponse>) in
                switch response.result {
                case .success(let imageResponse):
                    guard let imageString = imageResponse.rows.first?.fields.avatarImage else {
                        return completion(nil, RainbowClientError.couldNotLoadImage)
                    }
                    guard let imageData = Data(base64Encoded: imageString) else {
                        return completion(nil, RainbowClientError.couldNotLoadImage)
                    }
                    guard let image = UIImage(data: imageData) else {
                        return completion(nil, RainbowClientError.couldNotLoadImage)
                    }
                    return completion(image, nil)
                case .failure(let error):
                    return completion(nil, error)
                }
            }
        }
    }
}
