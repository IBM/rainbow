//
//  GuideViewController.swift
//  rainbow
//
//  Created by Anton McConville on 2018-05-11.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class BookletGuideController: BookletBaseController {
    
    @IBOutlet var contentImageView: UIImageView?
    @IBOutlet var pageTitleView: UILabel?
    @IBOutlet var statement: UITextView?
    @IBOutlet var button: UIButton?
    
    @IBAction func openLink(_ sender: UIButton) {
        performSegue(withIdentifier: "webkitSegue", sender: self)
    }
    
    var link: String = ""
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "webkitSegue" {
            guard let navController = segue.destination as? UINavigationController else {
                return
            }
            guard let webview = navController.topViewController as? AssetViewController else {
                return
            }
            webview.link = self.link
        }
    }
    
    // MARK: - Variables
    
    var image: UIImage = UIImage() {
        didSet {
            if let imageView = contentImageView {
                imageView.image = image
            }
        }
    }
    
    var titleString: String = "" {
        didSet {
            if let titleView = pageTitleView {
                titleView.text = titleString
            }
        }
    }
    
    var statementString: String = "" {
        didSet {
            if let statement = statement {
                statement.text = statementString
            }
        }
    }
    
    var linkString: String = "" {
        didSet {
            link = linkString
        }
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        
        button?.backgroundColor = .clear
        button?.tintColor = UIColor.RainbowColors.red
        button?.layer.cornerRadius = 15
        button?.layer.borderWidth = 0.5
        button?.layer.borderColor = UIColor.RainbowColors.red.cgColor
        
        super.viewDidLoad()
                contentImageView!.image = image
                pageTitleView!.text = titleString
                statement?.text = statementString
                link = linkString
      
    }
}
