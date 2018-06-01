//
//  KituraServerCredentials.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import CoreML
import VisualRecognitionV3

public struct ServerCredentials: Codable {
    var routes: VivaMLConfig
    var cloudant: VivaMLConfig
    var visualRecognition: VisualRecognitionAPIKey
}

public struct VivaMLConfig: Codable {
    var username: String
    var password: String
}

public struct VisualRecognitionAPIKey: Codable {
    var apiKey: String
}

class KituraServerCredentials {
    public static func loadedCredentials() -> ServerCredentials? {
        guard let path = Bundle.main.path(forResource: "WatsonMLClientCredentials", ofType: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoded = try JSONDecoder().decode(ServerCredentials.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
}

class VisualRecognitionUpdate {
    public static func loadLatestModel(completion: @escaping (_ latestModel: MLModel?, _ error: Error?) -> Void) {
        guard let key = KituraServerCredentials.loadedCredentials()?.visualRecognition.apiKey else {
            return completion(nil, nil)
        }
        let instance = VisualRecognition(apiKey: key, version: "2018-03-19")
        instance.updateLocalModel(classifierID: "DefaultCustomModel_2136728037", failure: { error in
            DispatchQueue.main.async {
                completion(nil, error)
            }
        }, success: {
            DispatchQueue.main.async {
                do {
                    let model = try instance.getLocalModel(classifierID: "DefaultCustomModel_2136728037")
                    completion(model, nil)
                } catch let error {
                    completion(nil, error)
                }
            }
        })
    }
}
