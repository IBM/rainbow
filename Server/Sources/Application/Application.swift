import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Generated
import Health
import KituraOpenAPI

// Service imports
import SwiftMetricsBluemix
import CouchDB
import IBMPushNotifications

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

enum ServiceInitializationError: Error {
    case cloudantError(String)
    case pushNotificationError(String)
}

class ApplicationServices {
    // Initialize services
    public var couchDBService: CouchDBClient?
    public var pushNotificationService: PushNotification?

    public init(cloudEnv: CloudEnv) throws {
        // Run service initializers
        do {
            couchDBService = try initializeServiceCloudant(cloudEnv: cloudEnv)
        } catch ServiceInitializationError.cloudantError(let reason) {
            Log.error("Error setting up Cloudant: \(reason)")
            couchDBService = nil
            return
        }
        
        do {
           pushNotificationService = try PushNotification.init(cloudEnv: cloudEnv, couchDBClient: couchDBService!)
        }catch ServiceInitializationError.pushNotificationError(let reason) {
            Log.error("Error setting up Push Notifications: \(reason)")
            pushNotificationService = nil
            //don't return. even if pushnotificatin is not setup let it run.
        }
    }
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    let swaggerPath = projectPath + "/definitions/watsonml.yaml"
    let services: ApplicationServices

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
        // Services
        services = try ApplicationServices(cloudEnv: cloudEnv)
    }

    func postInit() throws {
        // Middleware
        router.all(middleware: StaticFileServer())
        // Endpoints
        try initializeCRUDResources(cloudEnv: cloudEnv, router: router)
        initializeHealthRoutes(app: self)
        initializeSwaggerRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)
        setupBasicAuth(app: self)
        initializeScoreRoutes(app: self)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
