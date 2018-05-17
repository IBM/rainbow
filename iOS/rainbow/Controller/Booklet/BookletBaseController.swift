//
//  BookletBaseController.swift
//  rainbow
//
//  Created by Anton McConville on 2018-05-14.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class BookletBaseController: UIViewController {
    var itemIndex: Int = 0 // index in page view controller

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }

}
