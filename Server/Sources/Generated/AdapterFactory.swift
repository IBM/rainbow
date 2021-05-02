import Foundation
import Configuration
import CloudEnvironment
import CouchDB

public class AdapterFactory {
    let cloudEnv: CloudEnv

    init(cloudEnv: CloudEnv) {
        self.cloudEnv = cloudEnv
    }
}
