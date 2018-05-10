//
//  BookletController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-18.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import Foundation

import UIKit

struct Article: Codable {
    let page: Int
    let title: String
    let subtitle: String
    let imageEncoded: String
    let subtext: String
    let description: String
    let link: String
}

class BookletViewController: UIViewController, UIPageViewControllerDataSource {
    
    private var pageViewController: UIPageViewController?
    
    private var pages: [Article]?
    private var pageCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = "https://anthony-blockchain.us-south.containers.mybluemix.net/pages"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if error != nil {
                print(error!.localizedDescription)
                print("No internet")
                
                // use booklet.json if no internet
                self.useDefaultPages()
            }
            
            guard let data = data else { return }
            
            do {
                //Decode retrived data with JSONDecoder and assing type of Article object
                let pages = try JSONDecoder().decode([Article].self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
//                    self.setupPageControl()
                }
            } catch let jsonError {
                print(jsonError)
                
                // use booklet.json if jsonError
                self.useDefaultPages()
            }
            }.resume()
    }
    
    private func useDefaultPages() {
        if let path = Bundle.main.url(forResource: "booklet", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: path, options: .mappedIfSafe)
                let pages = try JSONDecoder().decode([Article].self, from: jsonData)
                print(pages)
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
//                    self.setupPageControl()
                }
            } catch {
                print("couldn't parse JSON Data")
            }
        }
    }

    private func createPageViewController() {
        guard let pageController = self.storyboard?.instantiateViewController(withIdentifier: "booklet") as? UIPageViewController else {
            return
        }
        pageController.dataSource = self
        if self.pageCount > 0 {
            let firstController = getItemController(itemIndex: 0)!
            let startingViewControllers = [firstController]
            pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        }

        pageViewController = pageController
        pageViewController?.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.size.height)
        addChildViewController(pageViewController!)
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMove(toParentViewController: self)
    }
    
    private func setupPageControl() {
        guard let subviews = pageViewController?.view.subviews else {
            return
        }
        let pageControls = subviews.filter { $0 is UIPageControl }
        guard let pageControl = pageControls.first as? UIPageControl else {
            return
        }
        pageControl.backgroundColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor(red: 0.97, green: 0.84, blue: 0.88, alpha: 1.0)
        pageControl.currentPageIndicatorTintColor = UIColor(red: 0.87, green: 0.21, blue: 0.44, alpha: 1.0)
        self.view.addSubview(pageControl)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let itemController = viewController as? BookletItemController else {
            return nil
        }
        
        if itemController.itemIndex > 0 {
            return getItemController(itemIndex: itemController.itemIndex-1)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let itemController = viewController as? BookletItemController else {
            return nil
        }
        
        if itemController.itemIndex+1 < self.pageCount {
            return getItemController(itemIndex: itemController.itemIndex+1)
        }
        
        return nil
    }
    
    private func getItemController(itemIndex: Int) -> BookletItemController? {
        
        if itemIndex < self.pages!.count {
            guard let pageItemController = self.storyboard?.instantiateViewController(withIdentifier: "ItemController") as? BookletItemController else {
                return nil
            }
//            let pageItemController = self.storyboard!.instantiateViewController(withIdentifier: "ItemController") as! BookletItemController
            pageItemController.itemIndex = itemIndex
            pageItemController.titleString = self.pages![itemIndex].title
            pageItemController.subTitleString = self.pages![itemIndex].subtitle
            pageItemController.image = self.base64ToImage(base64: self.pages![itemIndex].imageEncoded)
            pageItemController.statementString = self.pages![itemIndex].description
            pageItemController.linkString = self.pages![itemIndex].link
            
            return pageItemController
        }
        
        return nil
    }
    
    func base64ToImage(base64: String) -> UIImage {
        var img: UIImage = UIImage()
        if !base64.isEmpty {
            let decodedData = NSData(base64Encoded: base64, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
            let decodedimage = UIImage(data: decodedData! as Data)
            img = (decodedimage as UIImage?)!
        }
        return img
    }
    
    // MARK: - Page Indicator
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pages!.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Additions
    
    func currentControllerIndex() -> Int {
        
        let pageItemController = self.currentController()
        
        if let controller = pageItemController as? BookletItemController {
            return controller.itemIndex
        }
        
        return -1
    }

    func currentController() -> UIViewController? {
        guard let count = self.pageViewController?.viewControllers?.count else {
            return nil
        }
        if count > 0 {
            return self.pageViewController?.viewControllers?.first
        }
        return nil
    }
}
