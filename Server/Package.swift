// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "watsonml",
    dependencies: [
      .package(url: "https://github.com/IBM-Swift/Kitura.git", .upToNextMinor(from: "2.7.0")),
      .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.7.1"),
      .package(url: "https://github.com/IBM-Swift/CloudEnvironment.git", from: "9.0.0"),
      .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from: "17.0.0"),
      .package(url: "https://github.com/RuntimeTools/SwiftMetrics.git", from: "2.0.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-OpenAPI.git", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Health.git", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", from: "2.1.0"),
      .package(url: "https://github.com/IBM-Swift/Kitura-Credentials.git", from: "2.4.1"),
      .package(url: "https://github.com/IBM-Swift/SwiftyRequest.git", from: "2.0.5"),
      .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsHTTP.git", from: "2.1.3"),
      .package(url: "https://github.com/ibm-bluemix-mobile-services/bluemix-pushnotifications-swift-sdk.git", .upToNextMajor(from: "1.2.0"))
    ],
    targets: [
      .target(name: "watsonml", dependencies: [ .target(name: "Application"), "Kitura" , "HeliumLogger"]),
      .target(name: "Application", dependencies: [ "Kitura", "CloudEnvironment","SwiftMetrics", "KituraOpenAPI", "Health", "CouchDB","Credentials","SwiftyRequest","CredentialsHTTP","IBMPushNotifications", 
.target(name: "Generated"),
      ]),
      .target(name: "Generated", dependencies: ["Kitura", "CloudEnvironment","SwiftyJSON", "SwiftMetrics","KituraOpenAPI","Health","CouchDB",], path: "Sources/Generated"),

      .testTarget(name: "ApplicationTests" , dependencies: [.target(name: "Application"), "Kitura","HeliumLogger" ])
    ]
)
