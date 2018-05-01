//
//  ScoreEntry.swift
//  rainbow
//
//  Created by David Okun IBM on 5/1/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation

struct ScoreEntry: Codable {
    var username: String
    var startDate: Date
    var finishDate: Date
    var anonymousIdentifier: String
}
