//
//  Authentication.swift
//  Application
//
//  Created by Sanjeev Ghimire on 5/14/18.
//

import Foundation
import SwiftyJSON

struct Authentication: Codable {
    var username: String
    var password: String
}

extension Authentication{
    init(document: JSON) {
        username = document["username"].stringValue
        password = document["password"].stringValue
    }
}
