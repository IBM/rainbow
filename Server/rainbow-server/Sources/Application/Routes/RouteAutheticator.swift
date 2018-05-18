//
//  RouteAutheticator.swift
//  Application
//
//  Created by Sanjeev Ghimire on 5/14/18.
//

import Foundation
import Credentials
import CredentialsHTTP
import LoggerAPI

func setupBasicAuth(app: App) {
    // Setup a dictionary of users. In general, these would be read in from a database
    // Encode salted passwords using a one way encoding such as PBKDF2 or bcrypt or etc.
    // For more information, see https://www.owasp.org/index.php/Password_Storage_Cheat_Sheet
    
    guard let client = app.services.couchDBService else {
        Log.error("Client not found")
        return
    }
    
    var userDB: [String: EncodedPassword] = [:]    
    Authentication.Persistence.get(from: client) { auth, error in
        guard let auth = auth else {
            Log.error("Authentication not loaded from database: \(String(describing:error?.localizedDescription))")
            return
        }
        do {
            userDB[auth.username] = try EncodedPassword(withName: auth.username, password: auth.password, encoding: .PBKDF2)
        } catch {
            Log.error("Error while encoding")
            return
        }
    }
    
    // setup basic credentials
    // include a verifyPassword in the constructor that is the callback to be used when
    // checking the username, password combination.
    // Callback returns a user profile if (username,password) is valid. Else, nil.
    let basicCredentials = CredentialsHTTPBasic( verifyPassword: { userId, password, callback in
        if let user = userDB[userId] {
            do {
                let result = try user.verifyPassword(withPassword: password)
                if result {
                    Log.debug("Successfully authenticated!")
                    callback(UserProfile(id: userId, displayName: userId, provider: "HTTPBasic-Kitura"))
                }
            } catch {
                Log.error("VerifyPassword internal error")
            }
        }
        
        // if userID or password do not match or internal error
        callback(nil)
    }, realm: "Kitura-Realm")
    
    // create credential object and register basic credential plugin
    let credentials = Credentials()
    credentials.register(plugin: basicCredentials)
    
    // register this middleware for all routes
    app.router.all("/watsonml", middleware: credentials)
    
    app.router.get("/watsonml", handler: { request, response, next in
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        do {
            // if userProfile exists, it means user logged in
            if let userProfile = request.userProfile {
                Log.debug("User Successfully Authenticated \(userProfile.id)")
                next()
                return
            }
            // if 401 returned
            Log.debug("User Authentication failed")
            try response.status(.unauthorized).send("You are not authorized to use this API").end()
        } catch {
            Log.error("Could not send unauthorized status.")
        }
        next()
    })
}
