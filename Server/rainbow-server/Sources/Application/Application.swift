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

public class ApplicationServices {
    // Initialize services
    public var couchDBService: CouchDBClient
    public let pushNotificationService: PushNotifications?

    public init(cloudEnv: CloudEnv) throws {
        // Run service initializers
        do {
            couchDBService = try initializeServiceCloudant(cloudEnv: cloudEnv)
            pushNotificationService = try initializeServicePush(cloudEnv: cloudEnv)
        } catch {
            couchDBService = CouchDBClient(connectionProperties: ConnectionProperties(host: "localhost", port: 5984, secured: false))
            pushNotificationService = nil
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
        initializeHealthRoutes(app: self)
        initializeScoreRoutes(app: self)
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
