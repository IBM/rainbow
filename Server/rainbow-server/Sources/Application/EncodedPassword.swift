//
//  EncodedPassword.swift
//  Application
//
//  Created by Sanjeev Ghimire on 5/14/18.
//

import LoggerAPI
import Cryptor
import Foundation

public class EncodedPassword {
    
    public enum SecureEncoding {
        case PBKDF2
        case scrypt
        case bcrypt
    }
    
    public enum EncodedPasswordError: Error {
        case invalidRecord
        case invalidEncoding
    }
    
    /// username
    private var userName: String
    /// salt used in the hashing
    private let salt: [UInt8]
    // length of salt and also encoded password
    private let saltLength: UInt
    // rounds of PBKDF2
    private let roundsOfPBKDF: UInt32
    // type of encoding
    private let encodingType: SecureEncoding
    /// hashed password
    private let encodedPassword: [UInt8]
    
    
    ///
    /// Initialize an EncodedPassword object
    ///
    /// Parameters:
    ///     userName:       username
    ///     password:       password
    ///     saltFromUser:   salt (optional). If not included, function will generate a random salt. Recommended to not be passed
    ///     encoding:       encoding type used to encode the salted password
    ///
    public init(withName name: String, password: String,
                usingSalt saltFromUser: [UInt8]? = nil, encoding: SecureEncoding) throws {
        
        // Define our constants
        let mySaltLength:UInt = 32
        let myRoundsOfPBKDF: UInt32 = 2
        
        let mySalt: [UInt8] = try saltFromUser ?? Random.generate(byteCount: Int(mySaltLength))
        
        salt = mySalt
        saltLength = mySaltLength
        roundsOfPBKDF = myRoundsOfPBKDF
        userName = name
        encodingType = encoding
        
        switch (encoding) {
        case .PBKDF2:
            encodedPassword = try PBKDF.deriveKey(fromPassword: password, salt: mySalt,
                                              prf: .sha512, rounds: roundsOfPBKDF,
                                              derivedKeyLength: saltLength)
        default:
            throw EncodedPasswordError.invalidEncoding
        }
        
        Log.verbose("init: userId = \(name), password = \(password), salt = \(mySalt), hash = \(encodedPassword)")
    }
    
    ///
    /// Verify the password passed with the input password
    /// this is done by encoding the input password and comparing the two encoded passwords.
    ///
    public func verifyPassword(withPassword testPassword: String) throws -> Bool{
        let testPassword_encoded: [UInt8]
        switch (encodingType) {
        case .PBKDF2:
            testPassword_encoded = try PBKDF.deriveKey(fromPassword: testPassword, salt: salt,
                                                   prf: .sha512, rounds: roundsOfPBKDF,
                                                   derivedKeyLength: saltLength)
        default:
            throw EncodedPasswordError.invalidEncoding
        }
        return ( encodedPassword == testPassword_encoded)
    }    
}
