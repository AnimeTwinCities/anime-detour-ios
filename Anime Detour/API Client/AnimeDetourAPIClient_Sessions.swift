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
    /**
    Download Session information, saving into the passed in context.
    */
    func refreshSessions(managedObjectContext: NSManagedObjectContext, dateFormatter: NSDateFormatter, completion: (() -> Void)?) {
        self.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
            if result == nil {
                if let error = error {
                    NSLog("Error fetching session list")
                }

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

                            var existingError: NSError?
                            if let results = context.executeFetchRequest(fetchRequest, error: &existingError) {
                                if let first = results.first as? Session {
                                    session = first
                                } else {
                                    session = createAndReturn()
                                }
                            } else {
                                session = createAndReturn()
                            }
                        } else {
                            session = createAndReturn()
                        }

                        session.update(jsonObject: json, jsonDateFormatter: dateFormatter)

                        sessionsInResponse.addObject(session.objectID)
                    }

                    let notInResponsePredicate = NSPredicate(format: "NOT (self in %@)", sessionsInResponse)!
                    let notInResponseFetchRequest = NSFetchRequest(entityName: Session.entityName)
                    notInResponseFetchRequest.predicate = notInResponsePredicate
                    if let notInResponseSessions = context.executeFetchRequest(notInResponseFetchRequest, error: nil) {
                        for session in notInResponseSessions as [Session] {
                            context.deleteObject(session)
                        }
                    }

                    var error: NSError?
                    if context.save(&error) {
                        // OK!
                    } else {
                        NSLog("Error saving sessions: \(error!)")
                    }

                    completion?()
                }
            }
        }
    }
}