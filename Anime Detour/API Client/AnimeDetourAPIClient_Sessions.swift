//
//  AnimeDetourAPIClient_Sessions.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/12/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import AnimeDetourDataModel
import AnimeDetourAPI
import CoreData

private typealias IndividualSessionJSONDataType = [String:AnyObject]
private typealias SessionsJSONDataType = [IndividualSessionJSONDataType]

extension AnimeDetourAPIClient {
    func fetchSessions(_ dataStatusDefaultsController: DataStatusDefaultsController, managedObjectContext: NSManagedObjectContext) {
        _ = self.sessionList { [weak self] (result: Any?, error: NSError?) -> () in
            guard let jsonSessions = result as? SessionsJSONDataType, jsonSessions.count > 0 else {
                if let error = error {
                    NSLog("Error fetching session list from server: \(error)")
                }
                return
            }
            
            guard let strongSelf = self else {
                return
            }
            
            let context = managedObjectContext
            context.perform { () -> Void in
                let sessionEntity = NSEntityDescription.entity(forEntityName: Session.entityName, in: context)!
                for json: [String : AnyObject] in jsonSessions {
                    let session = Session(entity: sessionEntity, insertInto: context)
                    session.update(jsonObject: json, jsonDateFormatter: strongSelf.dateFormatter)
                }
                
                do {
                    try context.save()
                    dataStatusDefaultsController.sessionsFetchRequired = false
                    dataStatusDefaultsController.lastSessionsClearDate = Date()
                    
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
    func refreshSessions(_ managedObjectContext: NSManagedObjectContext, completion: (() -> Void)?) {
        _ = self.sessionList { [weak self] (result: Any?, error: NSError?) -> () in
            guard let jsonSessions = result as? SessionsJSONDataType, jsonSessions.count > 0 else {
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
            
            let context = managedObjectContext
            context.perform { () -> Void in
                let sessionsInResponse = jsonSessions.map { json in
                    return strongSelf.createOrUpdateSessionFor(json, context: context)
                }
                
                let notInResponsePredicate = NSPredicate(format: "NOT (self in %@)", sessionsInResponse)
                let notInResponseFetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
                notInResponseFetchRequest.predicate = notInResponsePredicate
                do {
                    let notInResponseSessions = try context.fetch(notInResponseFetchRequest)
                    for session in notInResponseSessions {
                        context.delete(session)
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
    fileprivate func createOrUpdateSessionFor(_ json: IndividualSessionJSONDataType, context: NSManagedObjectContext) -> NSManagedObjectID {
        var foundSession: Session?
        if let id = json[SessionJSONKeys.sessionID.rawValue] as? String {
            let existingPredicate = NSPredicate(format: "sessionID == %@", id)
            let fetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
            fetchRequest.predicate = existingPredicate
            fetchRequest.fetchLimit = 1
            
            let results = try? context.fetch(fetchRequest)
            foundSession = results?.first
        }
        
        let sessionEntity = NSEntityDescription.entity(forEntityName: Session.entityName, in: context)!
        let session = foundSession ?? Session(entity: sessionEntity, insertInto: context)
        
        session.update(jsonObject: json, jsonDateFormatter: dateFormatter)
        return session.objectID
    }
}
