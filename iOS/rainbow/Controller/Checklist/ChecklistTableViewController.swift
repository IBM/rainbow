//
//  ChecklistTableViewController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit

class ChecklistTableViewCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView?
    @IBOutlet weak var itemLabel: UILabel?
    @IBOutlet weak var minutesFoundLabel: UILabel?
    @IBOutlet weak var checkboxView: UIImageView?
}

class ChecklistTableViewController: UITableViewController {
    var gameConfigObjects: [ObjectConfig]? {
        do {
            let objects = try GameConfig.load()
            return objects.sorted { $0.name < $1.name }
        } catch {
            return nil
        }
    }
    var currentGame: ScoreEntry? {
        do {
            let possibleGames = try ScoreEntry.ClientPersistence.getAll()
            let yourGames = possibleGames.filter { $0.username == "dokun1" }
            let yourSortedGames = yourGames.sorted {
                if yourGames.count == 1 {
                    return true
                } else {
                    guard let firstStartDate = $0.startDate else {
                        return false
                    }
                    guard let secondStartDate = $1.startDate else {
                        return false
                    }
                    return firstStartDate < secondStartDate
                }
            }
            return yourSortedGames.first
        } catch {
            return nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("switched to checklist")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let gameConfigObjects = gameConfigObjects else {
            return 0
        }
        return gameConfigObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = UITableViewCell(style: .default, reuseIdentifier: "ChecklistTableViewCell")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChecklistTableViewCell", for: indexPath) as? ChecklistTableViewCell else {
            return defaultCell
        }
        guard let configObject = gameConfigObjects?[indexPath.row] else {
            return defaultCell
        }
        cell.iconView?.image = configObject.getColorImage()
        cell.itemLabel?.text = configObject.name
        cell.minutesFoundLabel?.text = "69 Minutes"
        cell.checkboxView?.image = #imageLiteral(resourceName: "checkmark")
        return cell
    }
}
