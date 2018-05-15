//
//  MainTabBarController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(MainTabBarController.deviceRegistrationComplete(notification:)), name: Notification.Name("watson-ml-device-token-registered"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("main controller shows")

    }
    
    @objc func deviceRegistrationComplete(notification: Notification) {
        DispatchQueue.main.async {
            guard let deviceID = notification.object as? String else {
                return
            }
            do {
                let savedEntry = try ScoreEntry.ClientPersistence.get()
                if savedEntry.deviceIdentifier == nil {
                    AvatarClient.getRandomAvatar { avatar, error in
                        if error != nil {
                            // we have an error
                        } else {
                            if let avatar = avatar {
                                self.saveNewUser(deviceID: deviceID, avatar: avatar)
                            }
                        }
                    }
                }
            } catch {
                AvatarClient.getRandomAvatar { avatar, error in
                    if error != nil {
                        // we have an error
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
        let newEntry = ScoreEntry(id: nil, username: avatar.name, startDate: nil, finishDate: nil, deviceIdentifier: deviceID, avatarImage: avatar.image, objects: nil, totalTime: nil)
        do {
            try ScoreEntry.ClientPersistence.save(entry: newEntry)
            let savedEntry = try ScoreEntry.ClientPersistence.get()
            print(String(describing: savedEntry))
        } catch let error {
            print("error during initial user save: \(error.localizedDescription)")
        }
    }
}
