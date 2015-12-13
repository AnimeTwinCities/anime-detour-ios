//
//  AnimeDetourAPIClient_Sessions.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/12/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import AnimeDetourAPI
import CoreData

extension AnimeDetourAPIClient {
    func fetchSessions(dataStatusDefaultsController: DataStatusDefaultsController, managedObjectContext: NSManagedObjectContext) {
        self.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
            guard let result = result where result.count > 0 else {
                if let error = error {
                    NSLog("Error fetching session list from server: \(error)")
                }
                return
            }
            
            guard let strongSelf = self else {
                return
            }
            
            guard let jsonSessions = result as? [[String : String]] else { return }
            let context = managedObjectContext
            context.performBlock { () -> Void in
                let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
                for json: [String : String] in jsonSessions {
                    let session = Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                    session.update(jsonObject: json, jsonDateFormatter: strongSelf.dateFormatter)
                }
                
                do {
                    try context.save()
                    dataStatusDefaultsController.sessionsFetchRequired = false
                    dataStatusDefaultsController.lastSessionsClearDate = NSDate()
                    
                    dataStatusDefaultsController.synchronizeDefaults()
                } catch {
                    let error = error
                    NSLog("Error saving sessions: \(error)")
                }
            }
        }
    }
    
    /**
    Download Session information, saving into the passed in context.
    */
    func refreshSessions(managedObjectContext: NSManagedObjectContext, completion: (() -> Void)?) {
        self.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
            guard let result = result where result.count > 0 else {
                if let error = error {
                    NSLog("Error fetching session list: \(error)")
                }
                completion?()
                return
            }

            guard let strongSelf = self else {
                completion?()
                return
            }
            
            guard let jsonSessions = result as? [[String : String]] else {
                completion?()
                return
            }
            
            let context = managedObjectContext
            context.performBlock { () -> Void in
                let sessionsInResponse = jsonSessions.map { json in
                    return strongSelf.createOrUpdateSessionFor(json, context: context)
                }
                
                let notInResponsePredicate = NSPredicate(format: "NOT (self in %@)", sessionsInResponse)
                let notInResponseFetchRequest = NSFetchRequest(entityName: Session.entityName)
                notInResponseFetchRequest.predicate = notInResponsePredicate
                do {
                    let notInResponseSessions = try context.executeFetchRequest(notInResponseFetchRequest)
                    for session in notInResponseSessions as! [NSManagedObject] {
                        context.deleteObject(session)
                    }
                } catch {
                    let error = error as NSError
                    NSLog("Error fetching sessions not in latest response: \(error)")
                }
                
                do {
                    try context.save()
                } catch {
                    let error = error as NSError
                    NSLog("Error saving sessions: \(error)")
                }
                
                completion?()
            }
        }
    }
    
    /**
     Find the session corresponding to the JSON, or create one if none exists, then update it.
     
     Returns the object ID of the found or created `Session`.
     */
    private func createOrUpdateSessionFor(json: [String : String], context: NSManagedObjectContext) -> NSManagedObjectID {
        var foundSession: Session?
        if let id = json[SessionJSONKeys.sessionID] {
            let existingPredicate = NSPredicate(format: "sessionID == %@", id)
            let fetchRequest = NSFetchRequest(entityName: Session.entityName)
            fetchRequest.predicate = existingPredicate
            fetchRequest.fetchLimit = 1
            
            let results = try? context.executeFetchRequest(fetchRequest)
            foundSession = results?.first as? Session
        }
        
        let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
        let session = foundSession ?? Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
        
        session.update(jsonObject: json, jsonDateFormatter: dateFormatter)
        return session.objectID
    }
}
