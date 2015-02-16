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
        let context = self.coreDataController.createManagedObjectContext(.PrivateQueueConcurrencyType)
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: context, queue: NSOperationQueue.mainQueue(), usingBlock: { [weak self] (note: NSNotification!) -> Void in
            self?.updateMainContext(saveNotification: note)
            return
        })
        return context
    }()
    lazy var primaryContext: NSManagedObjectContext = {
        return self.coreDataController.managedObjectContext
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.setColors(application)

        let guestsFetchRequiredKey = "guestsFetchRequiredKey"
        let sessionsFetchRequiredKey = "sessionsFetchRequiredKey"
        let lastGuestsClearDateKey = "lastGuestsClearDateKey"
        let lastSessionsClearDateKey = "lastSessionsClearDateKey"

        // Default last-must-be-cleared dates, set way in the past.
        let defaultGuestsClearDate = NSDate(timeIntervalSince1970: 0)
        let defaultSessionsClearDate = NSDate(timeIntervalSince1970: 0)

        let defaultUserDefaults: [NSObject : AnyObject] = [
            guestsFetchRequiredKey : NSNumber(bool: true),
            sessionsFetchRequiredKey : NSNumber(bool: true),
            lastGuestsClearDateKey : defaultGuestsClearDate,
            lastSessionsClearDateKey : defaultSessionsClearDate,
        ]
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.registerDefaults(defaultUserDefaults)

        // Latest must-be-cleared dates, e.g. if this version of the app points
        // at a different data set and must discard and re-download data.
        let calendar = NSCalendar.currentCalendar()
        let timezone = NSTimeZone(name: "America/Chicago")!
        calendar.timeZone = timezone
        let components = NSDateComponents()
        components.day = 15
        components.month = 2
        components.year = 2015
        let guestsClearDate = calendar.dateFromComponents(components)!
        let sessionsClearDate = calendar.dateFromComponents(components)!

        let guestsNeedClearing = guestsClearDate.timeIntervalSinceDate(userDefaults.objectForKey(lastGuestsClearDateKey) as NSDate) > 0
        let sessionsNeedClearing = sessionsClearDate.timeIntervalSinceDate(userDefaults.objectForKey(lastSessionsClearDateKey) as NSDate) > 0
        if guestsNeedClearing || sessionsNeedClearing {
            self.coreDataController.clearPersistentStore()

            // Clearing the persistent store removes all sessions and guests, since they are both kept
            // in the same store, so we need to fetch them again.
            userDefaults.setBool(true, forKey: guestsFetchRequiredKey)
            userDefaults.setBool(true, forKey: sessionsFetchRequiredKey)
        }

        if userDefaults.boolForKey(sessionsFetchRequiredKey) {
            self.apiClient.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
                if result == nil {
                    if let error = error {
                        NSLog("Error fetching session list")
                    }

                    return
                }

                if let jsonSessions = result as? [[String : String]] {
                    if let context = self?.backgroundContext {
                        context.performBlock { () -> Void in
                            let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
                            for json: [String : String] in jsonSessions {
                                let session = Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                                session.update(jsonObject: json, jsonDateFormatter: self!.apiClient.dateFormatter)
                            }

                            var error: NSError?
                            if context.save(&error) {
                                userDefaults.setBool(false, forKey: sessionsFetchRequiredKey)
                                userDefaults.setObject(sessionsClearDate, forKey: lastSessionsClearDateKey)
                                userDefaults.synchronize()
                            } else {
                                NSLog("Error saving sessions: \(error!)")
                            }
                        }
                    }
                }
            }
        }

        if userDefaults.boolForKey(guestsFetchRequiredKey) {
            self.apiClient.guestList { [weak self] (result, error) -> () in
                if result == nil {
                    if let error = error {
                        NSLog("Error fetching guest list")
                    }

                    return
                }

                if let guestsJson = result as? [[String : AnyObject]] {
                    if let context = self?.backgroundContext {
                        context.performBlock { () -> Void in
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
                                userDefaults.setBool(false, forKey: guestsFetchRequiredKey)
                                userDefaults.setObject(guestsClearDate, forKey: lastGuestsClearDateKey)
                                userDefaults.synchronize()
                            } else {
                                NSLog("Error saving guests: \(error!)")
                            }
                        }
                    }
                }
            }
        }

        return true
    }

    /// Merge changes from a save notification into the primary, main thread-only MOC.
    private func updateMainContext(saveNotification notification: NSNotification) {
        self.primaryContext.performBlock {
            self.primaryContext.mergeChangesFromContextDidSaveNotification(notification)
        }
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

        let textHeaderAppearanceProxy = TextHeaderCollectionReusableView.appearance()
        textHeaderAppearanceProxy.backgroundColor = mainColor
        textHeaderAppearanceProxy.tintColor = secondaryColor
    }
}

