//
//  KituraServerCredentials.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

public struct ServerCredentials: Codable {
    var routes: VivaMLConfig
    var cloudant: VivaMLConfig
}

public struct VivaMLConfig: Codable {
    var username: String
    var password: String
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
