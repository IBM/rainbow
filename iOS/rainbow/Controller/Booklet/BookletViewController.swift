//
//  BookletController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-18.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import Foundation
import UIKit

struct Page: Codable {
    let type: String
    let title: String
    let imagePath: String
    let imageURL: String
    let subtitle: String
    let description: String
    let order: Int
    let link: String
}

class BookletViewController: UIViewController, UIPageViewControllerDataSource {
    
    private var pageViewController: UIPageViewController?
    
    private var pages: [Page]?
    private var pageCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        useDefaultPages()
        
        let urlString = "https://raw.githubusercontent.com/IBM/watsonml-booklet-data/master/booklet.json"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if error != nil {
                print(String(describing: error?.localizedDescription))
                print("No internet")
                // use Booklet.json if no internet
                self.useDefaultPages()
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //Decode retrived data with JSONDecoder and assing type of Article object
                let pages = try JSONDecoder().decode([Page].self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
                    self.setupPageControl()
                }
            } catch let jsonError {
                print(jsonError)
                
                // use booklet.json if jsonError
                self.useDefaultPages()
            }
        }.resume()
    }
    
    private func useDefaultPages() {
        if let path = Bundle.main.url(forResource: "Booklet", withExtension: "json") {
            do {
                let jsonData = try Data(contentsOf: path, options: .mappedIfSafe)
                let pages = try JSONDecoder().decode([Page].self, from: jsonData)
                print(pages)
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
                    self.setupPageControl()
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
            guard let firstController = getItemController(itemIndex: 0) else {
                return
            }
            let startingViewControllers = [firstController]
            pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        }
        
        pageViewController = pageController
        guard let pageViewController = pageViewController else {
            return
        }
        pageViewController.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.size.height)
        addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
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
        guard let itemController = viewController as? BookletBaseController else {
            return nil
        }
        if itemController.itemIndex > 0 {
            return getItemController(itemIndex: itemController.itemIndex-1)
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let itemController = viewController as? BookletBaseController else {
            return nil
        }
        if itemController.itemIndex + 1 < self.pageCount {
            return getItemController(itemIndex: itemController.itemIndex+1)
        }
        return nil
    }
    
    private func getItemController(itemIndex: Int) -> BookletBaseController? {
        guard let pages = self.pages else {
            return nil
        }
        
        if itemIndex < pages.count {
            switch pages[itemIndex].type {
            case "instruction":
                print("instruction")
                guard let pageItemController = self.storyboard?.instantiateViewController(withIdentifier: "InstructionController") as? BookletInstructionController else {
                    return nil
                }
                pageItemController.itemIndex = itemIndex
                pageItemController.titleString = pages[itemIndex].title
                pageItemController.image = getBookletImage(page: pages[itemIndex])
                
                return pageItemController
                
            case "guide":
                print("guide")
                guard let pageItemController = self.storyboard?.instantiateViewController(withIdentifier: "GuideController") as? BookletGuideController else {
                    return nil
                }
                pageItemController.itemIndex = itemIndex
                pageItemController.titleString = pages[itemIndex].title
                pageItemController.statementString = pages[itemIndex].description
                pageItemController.linkString = pages[itemIndex].link
                pageItemController.image = getBookletImage(page: pages[itemIndex])
                
                return pageItemController
                
            default:
                guard let pageItemController = self.storyboard?.instantiateViewController(withIdentifier: "CoverController") as? BookletCoverController else {
                    return nil
                }
                pageItemController.itemIndex = itemIndex
                pageItemController.titleString = pages[itemIndex].title
                pageItemController.subTitleString = pages[itemIndex].subtitle
                pageItemController.image = getBookletImage(page: pages[itemIndex])
                
                return pageItemController
            }
        }
        
        return nil
    }
    
    func getBookletImage(page: Page) -> UIImage {
        if page.imagePath.isEmpty {
            guard let url = URL(string: page.imageURL) else {
                return UIImage()
            }
            guard let data = try? Data(contentsOf: url) else {
                print("There was an error!")
                return UIImage()
            }
            return UIImage(data: data)!
        } else {
            guard let image = UIImage(named: page.imagePath) else {
                return UIImage()
            }
            return image
        }
    }
    
    func base64ToImage(base64: String) -> UIImage {
        guard let data = Data(base64Encoded: base64) else {
            return #imageLiteral(resourceName: "checkmark")
        }
        guard let image = UIImage(data: data) else {
            return #imageLiteral(resourceName: "checkmark")
        }
        return image
    }
    
    // MARK: - Page Indicator
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        guard let pages = self.pages else {
            return 0
        }
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Additions
    
    func currentControllerIndex() -> Int {
        
        let pageItemController = self.currentController()
        
        if let controller = pageItemController {
            return controller.itemIndex
        }
        
        return -1
    }
    
    func currentController() -> BookletBaseController? {
        guard let count = self.pageViewController?.viewControllers?.count else {
            return nil
        }
        if count > 0 {
            return self.pageViewController?.viewControllers?.first as? BookletBaseController
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
}
