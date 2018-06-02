//
//  AvatarClient.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD

struct UserAvatar: Codable {
    var name: String
    var image: Data
}

class AvatarClient {
    private static func defaultAvatar() -> UserAvatar? {
        guard let path = Bundle.main.path(forResource: "DefaultAvatar", ofType: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoded = try JSONDecoder().decode(UserAvatar.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }

    static func getRandomAvatar(completion: @escaping (_ avatar: UserAvatar?, _ error: Error?) -> Void) {
        let request = RestRequest(method: .get, url: "https://avatar-rainbow.mybluemix.net/new", containsSelfSignedCert: false)
//        request.circuitParameters = CircuitParameters(timeout: 30, fallback: { _, _ in
//            DispatchQueue.main.async {
//                SVProgressHUD.showError(withStatus: "Could not get avatar")
//            }
//        })
        request.responseObject { (response: RestResponse<UserAvatar>) in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let avatarResponse):
                    completion(avatarResponse, nil)
                case .failure(let error):
                    if let defaultAvatar = defaultAvatar() {
                        completion(defaultAvatar, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
    }

}
