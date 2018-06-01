//
//  UserCount.swift
//  Application
//
//  Created by Sanjeev Ghimire on 6/1/18.
//

import Foundation

struct UserCount: Codable {
    var totalUsers: Int
    var totalUsersCompletingGame: Int
    
    init(totalUserCount: Int, totalUserCountCompletingGame: Int) {
        totalUsers = totalUserCount
        totalUsersCompletingGame = totalUserCountCompletingGame
    }    
}


