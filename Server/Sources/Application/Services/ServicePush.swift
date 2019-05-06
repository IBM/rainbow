import LoggerAPI
import CloudEnvironment
import IBMPushNotifications
import CouchDB
import Foundation

class PushNotification {

    var pushNotifications: PushNotifications?
    var couchDBClient: CouchDBClient?
    //Score Entry order by time taken
    var scoresOrderedByTotalTime = [ScoreEntry]()
    
    public init(cloudEnv: CloudEnv, couchDBClient: CouchDBClient) throws {
        guard let pushNotificationsCredentials = cloudEnv.getPushSDKCredentials(name: "push") else {
            throw ServiceInitializationError.pushNotificationError("Could not load credentials for Push Notifications.")
        }
        let pushNotifications = PushNotifications(
            pushApiKey: pushNotificationsCredentials.apiKey,
            pushAppGuid: pushNotificationsCredentials.appGuid,
            pushRegion: PushNotifications.Region.US_SOUTH
        )
        
        Log.info("Found and loaded credentials for Push Notifications.")
        self.pushNotifications = pushNotifications
        self.couchDBClient = couchDBClient
        
        // initialize sorted scores list
        ScoreEntry.Persistence.getScores(from: couchDBClient, completion: { scoreEntryArray, _ in
            if let scoreEntryArray = scoreEntryArray {
                Log.debug("Found score entries in database.")
                //sort scoreEntryArray by time taken
                self.scoresOrderedByTotalTime = scoreEntryArray
            } else {
                Log.debug("No score entries found in database.")
            }
            
        })
    }

    /// send push notification in two cases:
    /// 1- knocked from top spot of leaderboard
    /// 2- knocked from top 10
    //swiftlint:disable cyclomatic_complexity
    //swiftlint:disable function_body_length
    public func sendNotification(scoreEntry: ScoreEntry) {
        guard let couchDBClient = couchDBClient else {
            return
        }
 
        //find out the deviceIdentifier of the first place player
        guard let cacheWinner = scoresOrderedByTotalTime.first else {
            // if no one is in the cache, that means we add the single person to it and bail.
            scoresOrderedByTotalTime.append(scoreEntry)
            return
        }
        
        // we should also see who was in 10th place, if such an entry exists in the cache
        var potentialTenthPlace: ScoreEntry?
        for (index, entry) in self.scoresOrderedByTotalTime.enumerated() where index == 9 {
            potentialTenthPlace = entry
        }
        
        // query the database for the latest updates, which will have the first player's newest position after someone else played
        ScoreEntry.Persistence.getScores(from: couchDBClient) { databaseArray, error in
            //check to make sure we get an array from the database
            guard let databaseArray = databaseArray else {
                Log.error("Error retrieving score entries from database")
                return
            }
            
            // since the list we got back from the query is ordered, we can safely say that the first entry is the new first place entry, so let's get a handle on it
            guard let newWinnerEntry = databaseArray.first else {
                //if this array is empty, we still have a problem
                Log.error("No score entries present in database")
                return
            }

            // check to see if the "cache winner" is the same as the "new winner" - if not, we need to send some notifications
            if newWinnerEntry.id != cacheWinner.id {
                // there is a new person in first place, and we need to send a notification to the old first place person that they are no longer in first place

                guard let deviceIdentifier = cacheWinner.deviceIdentifier else {
                    print("Device Id not found so not sending push notification")
                    return
                }
                let target = Notification.Target(deviceIds: [deviceIdentifier])
                let message = Notification.Message.init(alert: Constant.knockedFromTop, url: nil)
                let notification = Notification.init(message: message, target: target)
                self.pushNotifications?.send(notification: notification) { _, _, error in
                    if error != nil {
                        print("Failed to send push notification. Error: \(error!)")
                    }
                }
            }
            
            // now we check to see if there is a tenth place in the cache
            if let oldTenthPlace = potentialTenthPlace {
                // now we check to see if the person who was in tenth place before is in any of the top ten spots in the latest query
                var found = false
                for index in 0...9 {
                    let checkEntry = databaseArray[index]
                    if checkEntry.id == oldTenthPlace.id {
                        // we found the person who was previously in tenth place in the top ten, we dont need to send any notifications
                        found = true
                        break
                    }
                }
                if !found {
                    // the person who was in tenth before is no longer in the top ten
                    guard let deviceId = oldTenthPlace.deviceIdentifier else {
                        print("Device Id not found so not sending push notification")
                        return
                    }
                    let target = Notification.Target(deviceIds: [deviceId])
                    let message = Notification.Message.init(alert: Constant.knockedFromTopTen, url: nil)
                    let notification = Notification.init(message: message, target: target)
                    self.pushNotifications?.send(notification: notification) { _, _, error in
                        if error != nil {
                            print("Failed to send push notification. Error: \(error!)")
                        }
                    }
                }
            }
            // we're all done, we update the cache, and we're done.
            self.scoresOrderedByTotalTime = databaseArray
        }
    }
}
