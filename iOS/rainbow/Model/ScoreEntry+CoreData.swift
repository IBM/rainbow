//
//  ScoreEntry+CoreData.swift
//  rainbow
//
//  Created by David Okun IBM on 5/10/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import Dispatch

enum ClientPersistenceError: Error {
    case couldNotFindAppDelegate
    case couldNotCreateEntity
    case couldNotSave
    case couldNotFetchResult
    case noMatchingResults
    case couldNotCastResult
    case entryAlreadyExists
    case uncaughtError(String)
}

fileprivate extension ObjectEntry {
    init?(managedObject: NSManagedObject, deviceIdentifier: String) {
        if deviceIdentifier != managedObject.value(forKey: "deviceIdentifier") as? String {
            return nil
        }
        guard let name = managedObject.value(forKey: "name") as? String else {
            return nil
        }
        guard let timestamp = managedObject.value(forKey: "timestamp") as? Date else {
            return nil
        }
        self.name = name
        self.timestamp = timestamp
    }

    func toManagedObject(description: NSEntityDescription, context: NSManagedObjectContext, deviceIdentifier: String) -> NSManagedObject {
        let managedEntry = NSManagedObject(entity: description, insertInto: context)
        managedEntry.setValue(self.name, forKey: "name")
        managedEntry.setValue(self.timestamp, forKey: "timestamp")
        managedEntry.setValue(deviceIdentifier, forKey: "deviceIdentifier")
        return managedEntry
    }
}

extension ScoreEntry {
    fileprivate static func deleteAllObjects(for deviceIdentifier: String) throws -> Bool {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw ClientPersistenceError.couldNotFindAppDelegate
        }
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataObjectEntry")
        request.returnsObjectsAsFaults = false
        do {
            guard let result = try context.fetch(request) as? [NSManagedObject] else {
                throw ClientPersistenceError.couldNotCastResult
            }
            for data in result {
                guard let queryIdentifier = data.value(forKey: "deviceIdentifier") as? String else {
                    continue
                }
                if queryIdentifier == deviceIdentifier {
                    context.delete(data)
                    try context.save()
                }
            }
            return true
        } catch let error {
            throw error
        }
    }

    fileprivate static func getAllObjects(for deviceIdentifier: String) throws -> [ObjectEntry] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw ClientPersistenceError.couldNotFindAppDelegate
        }
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataObjectEntry")
        request.returnsObjectsAsFaults = false
        do {
            guard let result = try context.fetch(request) as? [NSManagedObject] else {
                throw ClientPersistenceError.couldNotCastResult
            }
            var newObjects = [ObjectEntry]()
            for data in result {
                guard let newObject = ObjectEntry(managedObject: data, deviceIdentifier: deviceIdentifier) else {
                    continue
                }
                newObjects.append(newObject)
            }
            return newObjects
        } catch {
            throw ClientPersistenceError.couldNotFetchResult
        }
    }

    fileprivate static func saveObjects(entries: [ObjectEntry], deviceIdentifier: String) throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw ClientPersistenceError.couldNotFindAppDelegate
        }
        let context = appDelegate.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "DataObjectEntry", in: context) else {
            throw ClientPersistenceError.couldNotCreateEntity
        }
        for entry in entries {
            _ = entry.toManagedObject(description: entity, context: context, deviceIdentifier: deviceIdentifier)
            do {
                try context.save()
            } catch let error {
                throw ClientPersistenceError.uncaughtError(error.localizedDescription)
            }
        }
    }

    fileprivate init?(managedObject: NSManagedObject) {
        guard let username = managedObject.value(forKey: "username") as? String else {
            return nil
        }
        guard let deviceIdentifier = managedObject.value(forKey: "deviceIdentifier") as? String else {
            return nil
        }
        if let avatarImageString = managedObject.value(forKey: "avatarImage") as? String {
            self.avatarImage = Data(base64Encoded: avatarImageString)
        } else {
            self.avatarImage = nil
        }
        self.id = managedObject.value(forKey: "id") as? String
        self.startDate = managedObject.value(forKey: "startDate") as? Date
        self.finishDate = managedObject.value(forKey: "finishDate") as? Date
        self.username = username
        self.deviceIdentifier = deviceIdentifier
        self.totalTime = nil
        do {
            let objects = try ScoreEntry.getAllObjects(for: deviceIdentifier)
            if objects.count > 0 {
                self.objects = objects
            } else {
                self.objects = nil
            }
        } catch {
            return nil
        }
    }

    fileprivate func toManagedObject(description: NSEntityDescription, context: NSManagedObjectContext) -> NSManagedObject {
        let managedEntry = NSManagedObject(entity: description, insertInto: context)
        managedEntry.setValue(self.id, forKey: "id")
        managedEntry.setValue(self.username, forKey: "username")
        managedEntry.setValue(self.deviceIdentifier, forKey: "deviceIdentifier")
        managedEntry.setValue(self.avatarImage?.base64EncodedString(), forKey: "avatarImage")
        managedEntry.setValue(self.startDate, forKey: "startDate")
        managedEntry.setValue(self.finishDate, forKey: "finishDate")
        return managedEntry
    }

    class ClientPersistence {
        private static func entryExists(for deviceIdentifier: String?) throws -> NSManagedObject? {
            guard let deviceIdentifier = deviceIdentifier else {
                return nil
            }
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                throw ClientPersistenceError.couldNotFindAppDelegate
            }
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataScoreEntry")
            request.returnsObjectsAsFaults = false
            do {
                guard let result = try context.fetch(request) as? [NSManagedObject] else {
                    throw ClientPersistenceError.couldNotCastResult }
                for data in result {
                    guard let queryEntry = ScoreEntry(managedObject: data), let queryIdentifier = queryEntry.deviceIdentifier else {
                        continue
                    }
                    if queryIdentifier == deviceIdentifier {
                        return data
                    }
                }
                return nil
            } catch {
                throw ClientPersistenceError.couldNotFetchResult
            }
        }

        private static func delete(scoreEntryObject: NSManagedObject, from context: NSManagedObjectContext) throws -> Bool {
            guard let deviceIdentifier = scoreEntryObject.value(forKey: "deviceIdentifier") as? String else {
                return false
            }
            do {
                if try ScoreEntry.deleteAllObjects(for: deviceIdentifier) {
                    context.delete(scoreEntryObject)
                    try context.save()
                    return true
                } else {
                    return false
                }
            } catch let error {
                throw error
            }
        }
        
        /// this function will give you back the currently saved instance of ScoreEntry
        /// Note: there should only ever be one sav
        static func get() throws -> ScoreEntry {
            do {
                let entry: ScoreEntry = try DispatchQueue(label: "core-data-rainbow-queue", qos: .userInitiated).sync {
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                        throw ClientPersistenceError.couldNotFindAppDelegate
                    }
                    let context = appDelegate.persistentContainer.viewContext
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataScoreEntry")
                    request.returnsObjectsAsFaults = false
                    do {
                        guard let result = try context.fetch(request) as? [NSManagedObject] else {
                            throw ClientPersistenceError.couldNotCastResult }
                        guard let firstResult = result.first else {
                            throw ClientPersistenceError.noMatchingResults
                        }
                        guard let newEntry = ScoreEntry(managedObject: firstResult) else {
                            throw ClientPersistenceError.couldNotCastResult
                        }
                        return newEntry
                    } catch {
                        throw ClientPersistenceError.couldNotFetchResult
                    }
                }
                return entry
            } catch let error {
                throw error
            }
        }

        /// this function will let you save an object of type ScoreEntry
        /// Note: this will overwrite any ScoreEntry object that exists in the datastore with the same ID.
        static func save(entry: ScoreEntry) throws {
            do {
                try DispatchQueue(label: "core-data-rainbow-queue", qos: .userInitiated).sync {
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                        throw ClientPersistenceError.couldNotFindAppDelegate
                    }
                    let context = appDelegate.persistentContainer.viewContext
                    guard let entity = NSEntityDescription.entity(forEntityName: "DataScoreEntry", in: context) else {
                        throw ClientPersistenceError.couldNotCreateEntity
                    }
                    if let existingObject = try entryExists(for: entry.deviceIdentifier) {
                        if try ScoreEntry.ClientPersistence.delete(scoreEntryObject: existingObject, from: context) == false {
                            throw ClientPersistenceError.entryAlreadyExists
                        }
                    }
                    _ = entry.toManagedObject(description: entity, context: context)
                    try context.save()
                    if let objects = entry.objects, let deviceIdentifier = entry.deviceIdentifier {
                        try ScoreEntry.saveObjects(entries: objects, deviceIdentifier: deviceIdentifier)
                    }
                }
            } catch let error {
                throw error
            }
        }
    }
}
