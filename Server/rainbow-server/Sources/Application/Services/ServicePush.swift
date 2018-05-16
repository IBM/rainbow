import LoggerAPI
import CloudEnvironment
import IBMPushNotifications
import CouchDB
import Foundation

class PushNotification {

    var pushNotifications: PushNotifications?
    var couchDBClient: CouchDBClient?
    //Score Entry order by time taken
    var scoresOrderedByTotalTime : [ScoreEntry] = []
    
    public init(cloudEnv: CloudEnv, couchDBClient:  CouchDBClient) throws {
        guard let pushNotificationsCredentials = cloudEnv.getPushSDKCredentials(name: "push") else {
            throw ServiceInitializationError.pushNotificationError("Could not load credentials for Push Notifications.")
        }
        let pushNotifications = PushNotifications(
            pushRegion: PushNotifications.Region.US_SOUTH,
            pushAppGuid: pushNotificationsCredentials.appGuid,
            pushAppSecret: pushNotificationsCredentials.appSecret
        )
        Log.info("Found and loaded credentials for Push Notifications.")
        self.pushNotifications = pushNotifications
        self.couchDBClient = couchDBClient
        
        // initialize sorted scores list
        ScoreEntry.Persistence.getScores(from: couchDBClient, completion: { scoreEntryArray, error in
            guard let scoreEntryArray = scoreEntryArray else {
                Log.error("Error while rertieving score entries")
                return
            }
            //sort scoreEntryArray by time taken
            self.scoresOrderedByTotalTime = scoreEntryArray
        })
    }
    
    
    /// send push notification in two cases:
    /// 1- knocked from top spot of leaderboard
    /// 2- knocked from top 10
    public func sendNotification(scoreEntry: ScoreEntry) -> Void {
        guard let couchDBClient = couchDBClient else {
            return
        }
 
        //find position of the score in the array
        let index = self.scoresOrderedByTotalTime.index(where: { (score) -> Bool in
            scoreEntry.id == score.id
        })
        
        //check if the user has been dropped from top 1 and top 10
        ScoreEntry.Persistence.getScores(from: couchDBClient, completion: { scoreEntryArray, error in
            guard let scoreEntryArray = scoreEntryArray else {
                Log.error("Error while rertieving score entries")
                return
            }

            let indexFromDb = scoreEntryArray.index(where: { (score) -> Bool in
                scoreEntry.id == score.id
            })
            
            if indexFromDb  == nil {
                return
            }else if index == nil {
                self.scoresOrderedByTotalTime = scoreEntryArray
                return
            }
            
            let target = Notification.Target(deviceIds: [scoreEntry.deviceIdentifier!])
            if(index! == 0 && indexFromDb! > 0){
                //send notification
                let message = Notification.Message.init(alert: Constant.NOTIFICATION_MESSAGE_KNOCKED_FROM_TOP, url: nil)
                let notification = Notification.init(message: message, target: target)
                self.pushNotifications?.send(notification: notification) { (data, status, error) in
                    if error != nil {
                        print("Failed to send push notification. Error: \(error!)")
                    }
                }
            }else if(index! <= 9 && indexFromDb! > 9){
                //send notification
                let message = Notification.Message.init(alert: Constant.NOTIFICATION_MESSAGE_KNOCKED_FROM_TOP_TEN, url: nil)
                let notification = Notification.init(message: message, target: target)
                self.pushNotifications?.send(notification: notification) { (data, status, error) in
                    if error != nil {
                        print("Failed to send push notification. Error: \(error!)")
                    }
                }
            }
            //sort scoreEntryArray by time taken
            self.scoresOrderedByTotalTime = scoreEntryArray
        })
    }

}
