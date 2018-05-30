//
//  ScoreEntry+AvatarImages.swift
//  Application
//
//  Created by David Okun IBM on 5/30/18.
//

import Foundation
import Kitura
import SwiftyRequest
import CouchDB

enum RainbowAvatarError: Error {
    case couldNotCreateClient
    case couldNotLoadImage
}

private struct ImageResponseField: Codable {
    var avatarImage: String
}

private struct ImageResponseRow: Codable {
    var fields: ImageResponseField
}

private struct ImageResponse: Codable {
    var rows: [ImageResponseRow]
}

public struct AvatarImage: Codable {
    var imageData: Data?
}

fileprivate struct CloudantConfig: Codable {
    var username: String
    var password: String
    var url: String
}

class ScoreEntryAvatar {
    private static func getCloudantConfig() -> CloudantConfig? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = "./config/ServerConfig.json"
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoded = try JSONDecoder().decode(CloudantConfig.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
    
    static func getImage(with identifier: String?, completion: @escaping (_ image: Data?, _ error: Error?) -> Void) {
        guard let identifier = identifier else {
            return completion(nil, nil)
        }
        guard let config = getCloudantConfig() else {
            return completion(nil, nil)
        }
        let request = RestRequest(method: .post, url: config.url, containsSelfSignedCert: false)
        request.credentials = Credentials.basicAuthentication(username: config.username, password: config.password)
        request.headerParameters = ["Content-Type": "application/json"]
        let bodyString = "{\"q\": \"_id:\(identifier)\"}"
        request.messageBody = bodyString.data(using: .utf8)
        request.responseObject { (response: RestResponse<ImageResponse>) in
            switch response.result {
            case .success(let imageResponse):
                guard let imageString = imageResponse.rows.first?.fields.avatarImage else {
                    completion(nil, RainbowAvatarError.couldNotLoadImage)
                    return
                }
                guard let imageData = Data(base64Encoded: imageString) else {
                    completion(nil, RainbowAvatarError.couldNotLoadImage)
                    return
                }
                completion(imageData, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
}
