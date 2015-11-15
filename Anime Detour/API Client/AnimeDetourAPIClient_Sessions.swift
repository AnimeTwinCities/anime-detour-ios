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
            guard result != nil else {
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
    func refreshSessions(managedObjectContext: NSManagedObjectContext, dateFormatter: NSDateFormatter, completion: (() -> Void)?) {
        self.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
            if result == nil {
                if let error = error {
                    NSLog("Error fetching session list: \(error)")
                }
                completion?()

                return
            }

            let strongSelf: AnimeDetourAPIClient! = self
            if strongSelf == nil {
                return
            }

            if let jsonSessions = result as? [[String : String]] {
                let sessionsInResponse = NSMutableArray()

                let context = managedObjectContext
                context.performBlock { () -> Void in
                    let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
                    let createAndReturn = { () -> Session in
                        Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                    }

                    for json: [String : String] in jsonSessions {
                        var session: Session
                        if let id = json[SessionJSONKeys.sessionID] {
                            let existingPredicate = NSPredicate(format: "sessionID == %@", id)
                            let fetchRequest = NSFetchRequest(entityName: Session.entityName)
                            fetchRequest.predicate = existingPredicate
                            fetchRequest.fetchLimit = 1

                            do {
                                let results = try context.executeFetchRequest(fetchRequest)
                                if let first = results.first as? Session {
                                    session = first
                                } else {
                                    session = createAndReturn()
                                }
                            } catch {
                                session = createAndReturn()
                            }
                        } else {
                            session = createAndReturn()
                        }

                        session.update(jsonObject: json, jsonDateFormatter: dateFormatter)

                        sessionsInResponse.addObject(session.objectID)
                    }

                    let notInResponsePredicate = NSPredicate(format: "NOT (self in %@)", sessionsInResponse)
                    let notInResponseFetchRequest = NSFetchRequest(entityName: Session.entityName)
                    notInResponseFetchRequest.predicate = notInResponsePredicate
                    do {
                        let notInResponseSessions = try context.executeFetchRequest(notInResponseFetchRequest)
                        for session in notInResponseSessions as! [Session] {
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
    }
}