//
//  LeaderboardTableViewController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import SVProgressHUD
import Kingfisher

class LeaderboardTableViewCell: UITableViewCell {
    @IBOutlet weak var positionLabel: UILabel?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var timeElapsedLabel: UILabel?
}

class LeaderboardTableViewController: UITableViewController {
    var leaderboard: [ScoreEntry]?
    var yourUser: ScoreEntry?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SVProgressHUD.show(withStatus: "Loading Leaderboard...")
        do {
            yourUser = try ScoreEntry.ClientPersistence.get()
            getLeaderboard()
        } catch {
            print("Could not load your user")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh(sender:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    @objc func refresh(sender: UIRefreshControl) {
        SVProgressHUD.show(withStatus: "Getting Leaderboard...")
        getLeaderboard()
        sender.endRefreshing()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }
    
    private func getLeaderboard() {
        ScoreEntry.ServerCalls.getAll(for: yourUser?.id) { entries, error in
            DispatchQueue.main.async {
                if error != nil {
                    SVProgressHUD.showError(withStatus: "Could not load leaderboard")
                } else if entries != nil {
                    SVProgressHUD.dismiss()
                    self.leaderboard = entries
                    self.tableView.reloadData()
                } else {
                    print("Something unexpected happened")
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let leaderboard = leaderboard {
            return leaderboard.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let defaultCell = LeaderboardTableViewCell(style: .default, reuseIdentifier: "leaderboardTableViewCell")
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "leaderboardTableViewCell", for: indexPath) as? LeaderboardTableViewCell else {
            return defaultCell
        }
        guard let leaderboard = leaderboard else {
            return defaultCell
        }
        let currentEntry = leaderboard[indexPath.row]
        cell.usernameLabel?.text = currentEntry.username
        cell.positionLabel?.text = "\(indexPath.row + 1)"
        if let startDate = currentEntry.startDate, let finishDate = currentEntry.finishDate {
            cell.timeElapsedLabel?.text = GameTimer.getTimeFoundString(startDate: startDate, objectTimestamp: finishDate)
        }
        let urlString = "\(UIApplication.shared.rainbowServerBaseURL)avatar/leaderboardAvatar/\(currentEntry.id ?? "nil").png"
        if let url = URL(string: urlString) {
            cell.avatarImageView?.kf.indicatorType = .activity
            cell.avatarImageView?.kf.setImage(with: url)
        }
        if yourUser?.username == currentEntry.username {
            cell.backgroundColor = UIColor.RainbowColors.neutral
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
