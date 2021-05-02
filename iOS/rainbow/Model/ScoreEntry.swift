//
//  ScoreEntry.swift
//  rainbow
//
//  Created by David Okun IBM on 5/1/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

struct ObjectEntry: Codable {
    var name: String
    var timestamp: Date
}

struct ScoreEntry: Codable {
    //swiftlint:disable identifier_name
    var id: String?
    var username: String
    var startDate: Date?
    var finishDate: Date?
    var deviceIdentifier: String?
    var avatarImage: Data?
    var objects: [ObjectEntry]?
    var totalTime: Double?
}

extension ScoreEntry: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(username)
    }
    
    static func == (lhs: ScoreEntry, rhs: ScoreEntry) -> Bool {
        return lhs.id == rhs.id
    }
}
