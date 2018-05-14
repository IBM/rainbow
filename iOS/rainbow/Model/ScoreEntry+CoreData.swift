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
    case couldNotCastResult
    case entryAlreadyExists
    case uncaughtError(String)
}

fileprivate extension ObjectEntry {
    init?(managedObject: NSManagedObject, entryID: String) {
        if entryID != managedObject.value(forKey: "entryID") as? String {
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

    func toManagedObject(description: NSEntityDescription, context: NSManagedObjectContext, entryID: String) -> NSManagedObject {
        let managedEntry = NSManagedObject(entity: description, insertInto: context)
        managedEntry.setValue(self.name, forKey: "name")
        managedEntry.setValue(self.timestamp, forKey: "timestamp")
        managedEntry.setValue(entryID, forKey: "entryID")
        return managedEntry
    }
}

extension ScoreEntry {
    fileprivate static func deleteAllObjects(for entryID: String) throws -> Bool {
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
                guard let queryID = data.value(forKey: "entryID") as? String else {
                    continue
                }
                if queryID == entryID {
                    context.delete(data)
                    try context.save()
                }
            }
            return true
        } catch let error {
            throw error
        }
    }

    fileprivate static func getAllObjects(for entryID: String) throws -> [ObjectEntry] {
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
                guard let newObject = ObjectEntry(managedObject: data, entryID: entryID) else {
                    continue
                }
                newObjects.append(newObject)
            }
            return newObjects
        } catch {
            throw ClientPersistenceError.couldNotFetchResult
        }
    }

    fileprivate static func saveObjects(entries: [ObjectEntry], entryID: String) throws {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            throw ClientPersistenceError.couldNotFindAppDelegate
        }
        let context = appDelegate.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "DataObjectEntry", in: context) else {
            throw ClientPersistenceError.couldNotCreateEntity
        }
        for entry in entries {
            _ = entry.toManagedObject(description: entity, context: context, entryID: entryID)
            do {
                try context.save()
            } catch let error {
                throw ClientPersistenceError.uncaughtError(error.localizedDescription)
            }
        }
    }

    fileprivate init?(managedObject: NSManagedObject) {
        //swiftlint:disable identifier_name
        guard let id = managedObject.value(forKey: "id") as? String else {
            return nil
        }
        guard let username = managedObject.value(forKey: "username") as? String else {
            return nil
        }
        guard let deviceIdentifier = managedObject.value(forKey: "deviceIdentifier") as? String else {
            return nil
        }
        self.avatarImage = managedObject.value(forKey: "avatarImage") as? Data
        self.avatarURL = managedObject.value(forKey: "avatarURL") as? String
        self.startDate = managedObject.value(forKey: "startDate") as? Date
        self.finishDate = managedObject.value(forKey: "finishDate") as? Date
        self.id = id
        self.username = username
        self.deviceIdentifier = deviceIdentifier
        do {
            let objects = try ScoreEntry.getAllObjects(for: id)
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
        managedEntry.setValue(self.avatarImage, forKey: "avatarImage")
        managedEntry.setValue(self.avatarURL, forKey: "avatarURL")
        managedEntry.setValue(self.startDate, forKey: "startDate")
        managedEntry.setValue(self.finishDate, forKey: "finishDate")
        return managedEntry
    }

    class ClientPersistence {
        private static func entryExists(for id: String?) throws -> NSManagedObject? {
            guard let id = id else {
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
                    guard let queryEntry = ScoreEntry(managedObject: data), let queryID = queryEntry.id else {
                        continue
                    }
                    if queryID == id {
                        return data
                    }
                }
                return nil
            } catch {
                throw ClientPersistenceError.couldNotFetchResult
            }
        }

        private static func delete(scoreEntryObject: NSManagedObject, from context: NSManagedObjectContext) throws -> Bool {
            guard let id = scoreEntryObject.value(forKey: "id") as? String else {
                return false
            }
            do {
                if try ScoreEntry.deleteAllObjects(for: id) {
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
        
        /// this function will give you back all instances of `ScoreEntry` by unique id
        static func getAll() throws -> [ScoreEntry] {
            do {
                let entries: [ScoreEntry] = try DispatchQueue(label: "core-data-rainbow-queue", qos: .userInitiated).sync {
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                        throw ClientPersistenceError.couldNotFindAppDelegate
                    }
                    let context = appDelegate.persistentContainer.viewContext
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataScoreEntry")
                    request.returnsObjectsAsFaults = false
                    do {
                        guard let result = try context.fetch(request) as? [NSManagedObject] else {
                            throw ClientPersistenceError.couldNotCastResult }
                        var newEntries = [ScoreEntry]()
                        for data in result {
                            guard let newEntry = ScoreEntry(managedObject: data) else {
                                continue
                            }
                            newEntries.append(newEntry)
                        }
                        return newEntries
                    } catch {
                        throw ClientPersistenceError.couldNotFetchResult
                    }
                }
                return entries
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
                    if let existingObject = try entryExists(for: entry.id) {
                        if try ScoreEntry.ClientPersistence.delete(scoreEntryObject: existingObject, from: context) == false {
                            throw ClientPersistenceError.entryAlreadyExists
                        }
                    }
                    _ = entry.toManagedObject(description: entity, context: context)
                    try context.save()
                    if let objects = entry.objects, let entryID = entry.id {
                        try ScoreEntry.saveObjects(entries: objects, entryID: entryID)
                    }
                }
            } catch let error {
                throw error
            }
        }
    }
}

