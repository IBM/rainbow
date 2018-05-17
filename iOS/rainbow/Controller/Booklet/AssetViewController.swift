//
//  AssetViewController.swift
//  rainbow
//
//  Created by Anton McConville on 2018-05-09.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class AssetViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView?
    
    @IBAction func back(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var link: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: self.link)
        if let unwrappedURL = url {
            let request = URLRequest(url: unwrappedURL)
            let session = URLSession.shared
            
            let task = session.dataTask(with: request) { (_, _, error) in
                if error == nil, let webView = self.webView {
                    webView.loadRequest(request)
                } else {
                    print(String(describing: error))
                }
            }
            task.resume()
        }
    }
}
