import LoggerAPI
import CloudEnvironment
import IBMPushNotifications

func initializeServicePush(cloudEnv: CloudEnv) throws -> PushNotifications {
    guard let pushNotificationsCredentials = cloudEnv.getPushSDKCredentials(name: "push") else {
        throw ServiceInitializationError.PushNotificationError("Could not load credentials for Push Notifications.")
    }
    let pushNotifications = PushNotifications(
        pushRegion: pushNotificationsCredentials.region,
        pushAppGuid: pushNotificationsCredentials.appGuid,
        pushAppSecret: pushNotificationsCredentials.appSecret
    )
    Log.info("Found and loaded credentials for Push Notifications.")
    return pushNotifications
}
