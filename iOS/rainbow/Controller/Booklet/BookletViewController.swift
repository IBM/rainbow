//
//  BookletViewController.swift
//  rainbow
//
//  Created by David Okun IBM on 4/30/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit

class BookletViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("switched to booklet")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
