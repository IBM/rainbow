//
//  MainTabBarController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import SVProgressHUD

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.deviceRegistrationComplete(notification:)), name: Notification.Name("watson-ml-device-token-registered"), object: nil)
        SVProgressHUD.show(withStatus: "Preparing Watson ML...")
    }
    
    @objc func deviceRegistrationComplete(notification: Notification) {
        DispatchQueue.main.async {
            guard let deviceID = notification.object as? String else {
                SVProgressHUD.showError(withStatus: "Could not get device identifier")
                return
            }
            do {
                let savedEntry = try ScoreEntry.ClientPersistence.get()
                if savedEntry.deviceIdentifier == nil {
                    AvatarClient.getRandomAvatar { avatar, error in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: "Could not get avatar")
                        } else {
                            if let avatar = avatar {
                                self.saveNewUser(deviceID: deviceID, avatar: avatar)
                            }
                        }
                    }
                } else {
                    SVProgressHUD.dismiss()
                }
            } catch {
                AvatarClient.getRandomAvatar { avatar, error in
                    if error != nil {
                        SVProgressHUD.showError(withStatus: "Could not get avatar")
                    } else {
                        if let avatar = avatar {
                            self.saveNewUser(deviceID: deviceID, avatar: avatar)
                        }
                    }
                }
            } 
        }
    }
    
    private func saveNewUser(deviceID: String?, avatar: UserAvatar) {
        var newEntry = ScoreEntry(id: nil, username: avatar.name, startDate: nil, finishDate: nil, deviceIdentifier: deviceID, avatarImage: avatar.image, objects: nil, totalTime: nil)
        do {
            try ScoreEntry.ClientPersistence.save(entry: newEntry)
            //save the data to the cloud database
            
            ScoreEntry.ServerCalls.save(entry: newEntry, completion: { entry, error in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "Could not save user")
                    print("error during initial user save: \(String(describing: error?.localizedDescription))")
                } else {
                    guard let entry = entry else {
                        SVProgressHUD.showError(withStatus: "Could not save user")
                        print("error during initial user save: \(String(describing: error?.localizedDescription))")
                        return
                    }
                    newEntry.id = entry.id
                    DispatchQueue.main.async {
                        do {
                            try ScoreEntry.ClientPersistence.save(entry: newEntry)
                        } catch let saveError {
                            SVProgressHUD.showError(withStatus: "Could not save user")
                            print("error during initial user save: \(String(describing: saveError.localizedDescription))")
                        }
                    }
                }
                
            })            
            SVProgressHUD.showSuccess(withStatus: "Your username is \(newEntry.username)")
        } catch let error {
            SVProgressHUD.showError(withStatus: "Could not save user")
            print("error during initial user save: \(error.localizedDescription)")
        }
    }
}
