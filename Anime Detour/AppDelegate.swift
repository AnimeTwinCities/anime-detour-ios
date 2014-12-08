//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import ConScheduleKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var apiClient = ScheduleAPIClient.sharedInstance
    lazy var coreDataController = CoreDataController.sharedInstance
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.coreDataController.createManagedObjectContext(.PrivateQueueConcurrencyType)!
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: context, queue: NSOperationQueue.mainQueue(), usingBlock: { [weak self] (note: NSNotification!) -> Void in
            self?.updateMainContext(saveNotification: note)
            return
        })
        return context
    }()
    lazy var primaryContext: NSManagedObjectContext = {
        return self.coreDataController.managedObjectContext!
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window?.tintColor = UIColor.orangeColor()

        let initialSessionsFetchCompleteKey = "initialSessionFetchComplete"
        let defaultUserDefaults: [NSObject : AnyObject] = [initialSessionsFetchCompleteKey : NSNumber(bool: false)]
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.registerDefaults(defaultUserDefaults)

        if userDefaults.boolForKey(initialSessionsFetchCompleteKey) == false {
            self.apiClient.sessionList(since: nil, deletedSessions: false, completionHandler: { [weak self] (result: AnyObject?, error: NSError?) -> () in
                if result == nil {
                    if let error = error {
                        NSLog("Error fetching session list")
                    }

                    return
                }

                if let jsonSessions = result as? [[String : String]] {
                    if let context = self?.backgroundContext {
                        let sessionEntity = NSEntityDescription.entityForName("Session", inManagedObjectContext: context)!
                        for json: [String : String] in jsonSessions {
                            let session = Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                            session.update(jsonObject: json, jsonDateFormatter: self!.apiClient.dateFormatter)
                        }

                        var error: NSError?
                        context.save(&error)

                        if let error = error {
                            NSLog("Error saving sessions: \(error)")
                        } else {
                            userDefaults.setBool(true, forKey: initialSessionsFetchCompleteKey)
                        }
                    }
                }
            })
        }

        return true
    }

    /// Merge changes from a save notification into the main, main thread-only MOC.
    /// Must be called on the main thread.
    private func updateMainContext(saveNotification notification: NSNotification) {
        self.primaryContext.mergeChangesFromContextDidSaveNotification(notification)
    }
}

