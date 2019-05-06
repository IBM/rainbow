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

let watsonMLModelId = "WatsonMLModel_1753554316"

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
    public static func checkNewModelAvailable(completion: @escaping (_ available: Bool) -> Void) {
        guard let key = KituraServerCredentials.loadedCredentials()?.visualRecognition.apiKey else {
            return completion(false)
        }
        let instance = VisualRecognition(version: "2018-03-19", apiKey: key)
        
        instance.getClassifier(classifierID: watsonMLModelId) { classifier, error in
            
            if error != nil {
                return completion(false)
            }
            
            guard let status = classifier?.result?.status else {
                return completion(false)
            }
            if status != "ready" {
                return completion(false)
            }
            guard let updated = classifier?.result?.updated, let created = classifier?.result?.created else {
                return completion(false)
            }
            completion(updated > created)
        }
    }
    
    public static func loadLatestModel(useCloudAPI: Bool, completion: @escaping (_ latestModel: MLModel?, _ error: Error?) -> Void) {
        guard let key = KituraServerCredentials.loadedCredentials()?.visualRecognition.apiKey else {
            return completion(nil, nil)
        }
        let instance = VisualRecognition(version: "2018-03-19", apiKey: key)
        if !useCloudAPI {
            guard let list = try? instance.listLocalModels() else {
                return completion(nil, nil)
            }
            var models = [MLModel]()
            for modelLabel: String in list {
                do {
                    models.append(try instance.getLocalModel(classifierID: modelLabel))
                } catch {
                    continue
                }
            }
            if models.count == 0 {
                return completion(WatsonMLModel_1753554316().model, nil)
            } else {
                return completion(models.first, nil)
            }
        }
        
        instance.updateLocalModel(classifierID: watsonMLModelId) { _, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
            
            DispatchQueue.main.async {
                do {
                    let model = try instance.getLocalModel(classifierID: watsonMLModelId)
                    completion(model, nil)
                } catch let error {
                    completion(nil, error)
                }
            }
            
        }
    }
}
