//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import AnimeDetourAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var apiClient = AnimeDetourAPIClient.sharedInstance
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
        self.setColors(application)

        let initialGuestFetchCompleteKey = "initialGuestFetchComplete"
        let initialSessionsFetchCompleteKey = "initialSessionFetchComplete"
        let defaultUserDefaults: [NSObject : AnyObject] = [initialGuestFetchCompleteKey : NSNumber(bool: false),
            initialSessionsFetchCompleteKey : NSNumber(bool: false)]
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.registerDefaults(defaultUserDefaults)

        if !userDefaults.boolForKey(initialSessionsFetchCompleteKey) {
            self.apiClient.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
                if result == nil {
                    if let error = error {
                        NSLog("Error fetching session list")
                    }

                    return
                }

                if let jsonSessions = result as? [[String : String]] {
                    if let context = self?.backgroundContext {
                        let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
                        for json: [String : String] in jsonSessions {
                            let session = Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                            session.update(jsonObject: json, jsonDateFormatter: self!.apiClient.dateFormatter)
                        }

                        var error: NSError?
                        if context.save(&error) {
                            userDefaults.setBool(true, forKey: initialSessionsFetchCompleteKey)
                        } else {
                            if let error = error {
                                NSLog("Error saving sessions: \(error)")
                            } else {
                                NSLog("Unknown error saving sessions")
                            }
                        }
                    }
                }
            }
        }

        if !userDefaults.boolForKey(initialGuestFetchCompleteKey) {
            self.apiClient.guestList { [weak self] (result, error) -> () in
                if result == nil {
                    if let error = error {
                        NSLog("Error fetching guest list")
                    }

                    return
                }

                if let guestsJson = result as? [[String : AnyObject]] {
                    if let context = self?.backgroundContext {
                        let guestEntity = NSEntityDescription.entityForName(Guest.entityName, inManagedObjectContext: context)!

                        for category in guestsJson {
                            if let categoryName = category["categoryname"] as? String {
                                if let guests = category["guests"] as? [[String : String]] {
                                    for json: [String : String] in guests {
                                        let guest = Guest(entity: guestEntity, insertIntoManagedObjectContext: context)
                                        guest.update(categoryName: categoryName, jsonObject: json)
                                    }
                                }
                            }
                        }

                        var error: NSError?
                        if context.save(&error) {
                            userDefaults.setBool(true, forKey: initialGuestFetchCompleteKey)
                        } else {
                            if let error = error {
                                NSLog("Error saving guests: \(error)")
                            } else {
                                NSLog("Unknown error saving guests")
                            }
                        }
                    }
                }
            }
        }

        return true
    }

    /// Merge changes from a save notification into the main, main thread-only MOC.
    /// Must be called on the main thread.
    private func updateMainContext(saveNotification notification: NSNotification) {
        self.primaryContext.mergeChangesFromContextDidSaveNotification(notification)
    }

    private func setColors(application: UIApplication) {
        let mainColor = UIColor.adr_orange
        let secondaryColor = UIColor.whiteColor()

        self.window?.tintColor = mainColor

        let navBarAppearanceProxy = UINavigationBar.appearance()
        navBarAppearanceProxy.tintColor = secondaryColor
        navBarAppearanceProxy.barTintColor = mainColor
        navBarAppearanceProxy.translucent = false

        let attrs = [NSForegroundColorAttributeName : secondaryColor]
        navBarAppearanceProxy.titleTextAttributes = attrs
    }
}

