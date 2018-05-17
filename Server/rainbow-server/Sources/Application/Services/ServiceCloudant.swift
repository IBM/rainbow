import LoggerAPI
import CloudEnvironment
import CouchDB
import Configuration

func initializeServiceCloudant(cloudEnv: CloudEnv) throws -> CouchDBClient {
    #if os(macOS)
    Log.info("Running on macOS - defaulting to localhost for Cloudant DB")
    return CouchDBClient(connectionProperties: ConnectionProperties(host: "localhost", port: 5984, secured: false))
    #elseif os(Linux)
    // Load credentials for Cloudant/CouchDB using CloudEnvironment
    guard let cloudantCredentials = cloudEnv.getCloudantCredentials(name: "cloudant") else {
        throw ServiceInitializationError.cloudantError("Could not load credentials for Cloudant.")
    }
    let connectionProperties = ConnectionProperties(
        host: cloudantCredentials.host,
        port: Int16(cloudantCredentials.port),
        secured: cloudantCredentials.secured,
        username: cloudantCredentials.username,
        password: cloudantCredentials.password
    )
    let couchDBClient = CouchDBClient(connectionProperties: connectionProperties)
    Log.info("Found and loaded credentials for Cloudant.")
    return couchDBClient
    #endif
}
