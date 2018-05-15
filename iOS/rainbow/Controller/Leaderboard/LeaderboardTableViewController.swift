//
//  LeaderboardTableViewController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import UIKit
import SVProgressHUD

class LeaderboardTableViewCell: UITableViewCell {
    @IBOutlet weak var positionLabel: UILabel?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var timeElapsedLabel: UILabel?
}

class LeaderboardTableViewController: UITableViewController {
    var leaderboard: [ScoreEntry]?
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("switched to leaderboard")
        SVProgressHUD.setFont(UIFont.RainbowFonts.medium(size: 16))
        SVProgressHUD.setBackgroundColor(UIColor.RainbowColors.blue)
        SVProgressHUD.setForegroundColor(UIColor.white)
        SVProgressHUD.show(withStatus: "Getting Leaderboard...")
        getLeaderboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
    }
    
    private func getLeaderboard() {
        ScoreEntry.ServerCalls.getAll { entries, error in
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
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
