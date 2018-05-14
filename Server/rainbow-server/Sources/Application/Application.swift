import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

// Service imports
import CouchDB
import IBMPushNotifications

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

enum ServiceInitializationError: Error {
    case cloudantError(String)
    case pushNotificationError(String)
}

public class ApplicationServices {
    // Initialize services
    public var couchDBService: CouchDBClient?
    var pushNotificationService: PushNotification?

    public init(cloudEnv: CloudEnv) throws {
        // Run service initializers
        do {
            couchDBService = try initializeServiceCloudant(cloudEnv: cloudEnv)
            pushNotificationService = try PushNotification.init(cloudEnv: cloudEnv, couchDBClient: couchDBService!)
        } catch ServiceInitializationError.cloudantError(let reason) {
            Log.error("Error setting up Cloudant: \(reason)")
            couchDBService = nil
        } catch ServiceInitializationError.pushNotificationError(let reason) {
            Log.error("Error setting up Push Notifications: \(reason)")
            pushNotificationService = nil
        } catch {
            couchDBService = nil
            pushNotificationService = nil
            Log.error("Unhandled exception during service init.")
        }
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    let services: ApplicationServices

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
        // Services
        services = try ApplicationServices(cloudEnv: cloudEnv)
    }

    func postInit() throws {
        // Endpoints
        setupBasicAuth(app: self)
        initializeHealthRoutes(app: self)
        initializeScoreRoutes(app: self)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
