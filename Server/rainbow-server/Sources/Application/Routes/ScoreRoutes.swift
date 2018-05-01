//
//  ScoreRoutes.swift
//  Application
//
//  Created by David Okun IBM on 5/1/18.
//

import Foundation
import CouchDB
import LoggerAPI
import KituraContracts

//private var database: Database?

func initializeScoreRoutes(app: App) {
    //database = app.database
    
    app.router.get("/scores", handler: getAllEntries)
    app.router.get("/scores/:id", handler: getOneEntry)
    app.router.post("/scores", handler: addNewEntry)
    app.router.put("/scores", handler: updateEntry)
    app.router.delete("/scores", handler: deleteEntry)
}

func getAllEntries(completion: @escaping ([ScoreEntry]?, RequestError?) -> Void) {
    
}

func getOneEntry(anonymousIdentifier: String, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    
}

func addNewEntry(newEntry: ScoreEntry, completion: @escaping(ScoreEntry?, RequestError?) -> Void) {
    
}

func updateEntry(anonymousIdentifier: String, newEntry: ScoreEntry, completion: @escaping (ScoreEntry?, RequestError?) -> Void) {
    
}

func deleteEntry(anonymousIdentifier: String, completion: @escaping(RequestError?) -> Void) {
    
}
