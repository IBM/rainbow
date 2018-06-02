//
//  ParticipantViewController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/15/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit

class ParticipantViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var startDateLabel: UILabel?
    @IBOutlet weak var timeElapsedLabel: UILabel?
    @IBOutlet weak var scavagingSinceLabel: UILabel?
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var leaderboardButton: UIButton?
    @IBOutlet weak var nowPlayingLabel: UILabel?
    
    override func viewDidAppear(_ animated: Bool) {
        ScoreEntry.ServerCalls.getCount { count, _ in
            DispatchQueue.main.async {
                if let count = count {
                    self.nowPlayingLabel?.text = "\(count.totalUsers) Players"
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            let savedEntry = try ScoreEntry.ClientPersistence.get()
            nameTextField?.text = savedEntry.username
            guard let leaderboardButton = leaderboardButton else {
                return
            }
            leaderboardButton.backgroundColor = .clear
            leaderboardButton.tintColor = UIColor.RainbowColors.orange
            leaderboardButton.layer.cornerRadius = 20
            leaderboardButton.layer.borderWidth = 0.5
            leaderboardButton.layer.borderColor = UIColor.RainbowColors.orange.cgColor
            leaderboardButton.setTitleColor(UIColor.RainbowColors.orange, for: .normal)

            guard let imageData = savedEntry.avatarImage else {
                return
            }
            guard let image = UIImage(data: imageData) else {
                return
            }
            avatarImageView?.image = image
            
            let config = try GameConfig.load()
            var foundObjects = [ObjectEntry]()
            if let savedFoundObjects = savedEntry.objects {
                foundObjects = savedFoundObjects
            }
            progressLabel?.text = "\(foundObjects.count)/\(config.count)"
            
            guard let startDate = savedEntry.startDate else {
                startDateLabel?.text = "----"
                timeElapsedLabel?.text = "----"
                return
            }
            startDateLabel?.text = startDate.vivaFormatted
            if let finishDate = savedEntry.finishDate {
                scavagingSinceLabel?.text = "You finished!"
                timeElapsedLabel?.text = GameTimer.getTimeFoundString(startDate: startDate, objectTimestamp: finishDate)
            } else {
                scavagingSinceLabel?.text = "Playing since"
                timeElapsedLabel?.text = GameTimer.getTimeFoundString(startDate: startDate, objectTimestamp: Date())
            }
        } catch {
            print("")
        }
    }
}
