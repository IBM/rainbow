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
    @IBOutlet weak var progressLabel: UILabel?
    @IBOutlet weak var progressSlider: UISlider?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            let savedEntry = try ScoreEntry.ClientPersistence.get()
            nameTextField?.text = savedEntry.username
            guard let imageData = savedEntry.avatarImage else {
                return
            }
            guard let image = UIImage(data: imageData) else {
                return
            }
            avatarImageView?.image = image
            guard let startDate = savedEntry.startDate else {
                startDateLabel?.text = "----"
                timeElapsedLabel?.text = "----"
                return
            }
            startDateLabel?.text = startDate.watsonFormatted
            timeElapsedLabel?.text = GameTimer.getTimeFoundString(startDate: startDate, objectTimestamp: Date())
            let config = try GameConfig.load()
            var foundObjects = [ObjectEntry]()
            if let savedFoundObjects = savedEntry.objects {
                foundObjects = savedFoundObjects
            }
            let progress = Float(Double(foundObjects.count) / Double(config.count))
            progressLabel?.text = "\(Int(progress * 100))%"
            progressSlider?.value = progress
        } catch {
            print("")
        }
    }
}
