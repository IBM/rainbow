//
//  ScoreEntry+AvatarImages.swift
//  Application
//
//  Created by David Okun IBM on 5/30/18.
//

import Foundation
import Kitura
import SwiftyRequest

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

class ScoreEntryAvatar {
    static func getImage(with identifier: String?, completion: @escaping (_ image: Data?, _ error: Error?) -> Void) {
        guard let identifier = identifier else {
            return completion(nil, nil)
        }
        let request = RestRequest(method: .post, url: "https://241de9e3-46be-4625-a256-76eab61af5da-bluemix.cloudant.com/rainbow-entries/_design/avatarImage/_search/avatarImageIdx", containsSelfSignedCert: false)
        
        request.credentials = Credentials.basicAuthentication(username: "watsonml", password: "(C0r3MLiPh0neGam3!)")
        request.headerParameters = ["Content-Type": "application/json"]
        let bodyString = "{\"q\": \"_id:\(identifier)\"}"
        request.messageBody = bodyString.data(using: .utf8)
        request.responseObject { (response: RestResponse<ImageResponse>) in
            switch response.result {
            case .success(let imageResponse):
                guard let imageString = imageResponse.rows.first?.fields.avatarImage else {
                    return completion(nil, RainbowAvatarError.couldNotLoadImage)
                }
                guard let imageData = Data(base64Encoded: imageString) else {
                    return completion(nil, RainbowAvatarError.couldNotLoadImage)
                }
                return completion(imageData, nil)
            case .failure(let error):
                return completion(nil, error)
            }
        }
    }
}
