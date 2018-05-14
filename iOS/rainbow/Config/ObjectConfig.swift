//
//  ObjectConfig.swift
//  rainbow
//
//  Created by David Okun IBM on 5/14/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

struct ObjectConfig: Codable {
    var name: String
    var colorIcon: String
    var whiteIcon: String
    
    func getColorImage() -> UIImage {
        guard let image = UIImage(named: colorIcon) else {
            return #imageLiteral(resourceName: "info")
        }
        return image
    }
    
    func getWhiteImage() -> UIImage {
        guard let image = UIImage(named: whiteIcon) else {
            return #imageLiteral(resourceName: "info")
        }
        return image
    }
}

enum GameConfigError: Error {
    case noConfigFile
    case incorrectlyFormattedFile
    case other
}

class GameConfig {
    static func load() throws -> [ObjectConfig] {
        guard let path = Bundle.main.path(forResource: "GameObjects", ofType: "json") else {
            throw GameConfigError.noConfigFile
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoded = try JSONDecoder().decode([ObjectConfig].self, from: data)
            return decoded
        } catch {
            throw GameConfigError.incorrectlyFormattedFile
        }
    }
}
