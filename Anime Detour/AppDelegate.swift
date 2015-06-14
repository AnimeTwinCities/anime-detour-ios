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
    
    /**
    Indicates whether the user has given permission to send local notifications.
    Must be set early in `application:didFinishLaunchingWithOptions:`.
    */
    private var localNotificationsAllowed: Bool = false {
        didSet {
            let localNotificationsAllowed = self.localNotificationsAllowed
            self.updateSessionNotificationsEnabled(localNotificationsAllowed)
            
            if localNotificationsAllowed {
                if self.enableSessionNotificationsOnNotificationsEnabled {
                    self.userVisibleSessionSettings.favoriteSessionAlerts = true
                }
                
                self.enableSessionNotificationsOnNotificationsEnabled = false
            }
        }
    }
    private lazy var sessionNotificationScheduler: SessionNotificationScheduler = {
        let context = self.primaryContext
        let scheduler = SessionNotificationScheduler(managedObjectContext: context)
        scheduler.delegate = self
        return scheduler
    }()
    
    // MARK: - Settings
    
    private let internalSettings: InternalSettings = InternalSettings()
    private let userVisibleSessionSettings: SessionSettings = SessionSettings()
    private var enableSessionNotificationsOnNotificationsEnabled = false
    
    // MARK: - Application Delegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.setColors(application)

        #if DEBUG
            // no analytics
        #else
            let analytics = GAI.sharedInstance()
            analytics.dispatchInterval = 30 // seconds
            if let file = NSBundle.mainBundle().pathForResource("GoogleAnalyticsConfiguration", ofType: "plist") {
                if let analyticsDictionary = NSDictionary(contentsOfFile: file) {
                    if let analyticsID = analyticsDictionary["analyticsID"] as? String {
                        analytics.trackerWithTrackingId(analyticsID)
                    }
                }
            }
        #endif
        
        self.userVisibleSessionSettings.delegate = self
        
        let guestsFetchRequiredKey = "guestsFetchRequiredKey"
        let sessionsFetchRequiredKey = "sessionsFetchRequiredKey"
        let lastGuestsClearDateKey = "lastGuestsClearDateKey"
        let lastSessionsClearDateKey = "lastSessionsClearDateKey"

        // Default last-must-be-cleared dates, set way in the past.
        let defaultGuestsClearDate = NSDate(timeIntervalSince1970: 0)
        let defaultSessionsClearDate = NSDate(timeIntervalSince1970: 0)

        let defaultUserDefaults = [
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
        components.day = 16
        components.month = 2
        components.year = 2015
        let guestsClearDate = calendar.dateFromComponents(components)!
        let sessionsClearDate = calendar.dateFromComponents(components)!

        let guestsNeedClearing = guestsClearDate.timeIntervalSinceDate(userDefaults.objectForKey(lastGuestsClearDateKey) as! NSDate) > 0
        let sessionsNeedClearing = sessionsClearDate.timeIntervalSinceDate(userDefaults.objectForKey(lastSessionsClearDateKey) as! NSDate) > 0
        if guestsNeedClearing || sessionsNeedClearing {
            self.coreDataController.clearPersistentStore()

            // Clearing the persistent store removes all sessions and guests, since they are both kept
            // in the same store, so we need to fetch them again.
            userDefaults.setBool(true, forKey: guestsFetchRequiredKey)
            userDefaults.setBool(true, forKey: sessionsFetchRequiredKey)
        }

        if userDefaults.boolForKey(sessionsFetchRequiredKey) {
            self.apiClient.sessionList { [weak self] (result: AnyObject?, error: NSError?) -> () in
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
                let context = strongSelf.backgroundContext
                context.performBlock { () -> Void in
                    let sessionEntity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: context)!
                    for json: [String : String] in jsonSessions {
                        let session = Session(entity: sessionEntity, insertIntoManagedObjectContext: context)
                        session.update(jsonObject: json, jsonDateFormatter: self!.apiClient.dateFormatter)
                    }
                    
                    do {
                        try context.save()
                        userDefaults.setBool(false, forKey: sessionsFetchRequiredKey)
                        userDefaults.setObject(sessionsClearDate, forKey: lastSessionsClearDateKey)
                        userDefaults.synchronize()
                    } catch {
                        let error = error
                        NSLog("Error saving sessions: \(error)")
                    }
                }
            }
        }

        if userDefaults.boolForKey(guestsFetchRequiredKey) {
            self.apiClient.guestList { [weak self] (result, error) -> () in
                guard result != nil else {
                    if let error = error {
                        NSLog("Error fetching guest list from server: \(error)")
                    }

                    return
                }
                
                guard let strongSelf = self else {
                    return
                }

                guard let guestsJson = result as? [[String : AnyObject]] else { return }
                let context = strongSelf.backgroundContext
                context.performBlock { () -> Void in
                    let guestEntity = NSEntityDescription.entityForName(Guest.entityName, inManagedObjectContext: context)!
                    
                    for category in guestsJson {
                        guard let categoryName = category["categoryname"] as? String else {
                            continue
                        }
                        
                        guard let guests = category["guests"] as? [[String : String]] else {
                            continue
                        }
                        
                        for json: [String : String] in guests {
                            let guest = Guest(entity: guestEntity, insertIntoManagedObjectContext: context)
                            guest.update(categoryName: categoryName, jsonObject: json)
                        }
                    }
                    
                    do {
                        try context.save()
                        userDefaults.setBool(false, forKey: guestsFetchRequiredKey)
                        userDefaults.setObject(guestsClearDate, forKey: lastGuestsClearDateKey)
                        userDefaults.synchronize()
                    } catch {
                        let error = error
                        NSLog("Error saving guests: \(error)")
                    }
                }
            }
        }

        return true
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types == .None {
            self.localNotificationsAllowed = false
        } else {
            self.localNotificationsAllowed = true
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        self.localNotificationsAllowed = self.notificationPermissionsEnabled()
        self.updateSessionNotificationsEnabled(self.localNotificationsAllowed)
    }
    
    // MARK: - Presenting Alerts
    
    private func show(alertController: UIAlertController) {
        self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Session Notifications
    
    /**
    Ask the user if they'd like to enable notifications for upcoming favorited Sessions.
    Only requests push notification permissions if they agree.
    */
    private func askEnableSessionNotifications() {
        let alertController = UIAlertController(title: "Session Notifications", message: "Enable alerts for favorite sessions? You'll have to allow notifications from the app.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let accept = UIAlertAction(title: "Enable", style: UIAlertActionStyle.Default) { (action: UIAlertAction!) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.requestNotificationPermissions()
        }
        let cancel = UIAlertAction(title: "Not Now", style: UIAlertActionStyle.Cancel)  { (action: UIAlertAction!) -> Void in
            self.internalSettings.askedToEnableNotifications = true
            self.userVisibleSessionSettings.favoriteSessionAlerts = false
            return
        }
        
        alertController.addAction(cancel)
        alertController.addAction(accept)
        
        self.show(alertController)
    }
    
    /**
    Update the Session notification scheduler's notifications enabled setting
    based on our user visible settings' setting.
    */
    private func updateSessionNotificationsEnabled(localNotificationsAllowed: Bool) {
        let enabledInUserPref = self.userVisibleSessionSettings.favoriteSessionAlerts
        self.sessionNotificationScheduler.notificationsEnabled = self.localNotificationsAllowed && enabledInUserPref
    }

    /**
    Request permission to display the types of notifications we want to display.
    */
    private func requestNotificationPermissions() {
        self.internalSettings.askedSystemToEnableNotifications = true
        
        let application = UIApplication.sharedApplication()
        
        // Request all permissions
        let noteTypes: UIUserNotificationType = [UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge]
        let noteSettings = UIUserNotificationSettings(forTypes: noteTypes, categories: nil)
        application.registerUserNotificationSettings(noteSettings)
    }
    
    private func notificationPermissionsEnabled() -> Bool {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        return (settings?.types ?? .None) != .None
    }
    
    // MARK: - Core Data
    
    /**
    Merge changes from a save notification into the primary, main thread-only MOC.
    */
    private func updateMainContext(saveNotification notification: NSNotification) {
        self.primaryContext.performBlock {
            self.primaryContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    // MARK: - Settings
    
    @objc private func showSettings() {
        let application = UIApplication.sharedApplication()
        application.openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    // MARK: - Theming

    /**
    Set basic color theme for the app.
    */
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

        let segmentedControlHeaderAppearanceProxy = SegmentedControlCollectionReusableView.appearance()
        segmentedControlHeaderAppearanceProxy.backgroundColor = mainColor
        segmentedControlHeaderAppearanceProxy.tintColor = secondaryColor
    }
}

// MARK: - SessionFavoriteNotificationDelegate
extension AppDelegate: SessionFavoriteNotificationDelegate {
    func didChangeFavoriteSessions(count: Int) {
        if !self.internalSettings.askedToEnableNotifications && !self.userVisibleSessionSettings.favoriteSessionAlerts {
            self.enableSessionNotificationsOnNotificationsEnabled = true
            self.askEnableSessionNotifications()
        }
    }
}

// MARK: - SessionSettingsDelegate
extension AppDelegate: SessionSettingsDelegate {
    func didChangeSessionNotificationsSetting(enabled: Bool) {
        guard enabled else {
            return
        }
        
        guard self.internalSettings.askedToEnableNotifications else {
            self.askEnableSessionNotifications()
            return
        }
        
        guard self.internalSettings.askedSystemToEnableNotifications else {
            self.requestNotificationPermissions()
            return
        }
        
        guard self.localNotificationsAllowed else {
            // Disable the notification setting if notifications are not allowed
            self.userVisibleSessionSettings.favoriteSessionAlerts = false
            
            let alertController = UIAlertController(title: "Enable Notifications", message: "Enable notifications in the Settings app before enabling session alerts.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let settings = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) -> Void in
                self.showSettings()
                return
            })
            
            alertController.addAction(cancel)
            alertController.addAction(settings)
            
            self.show(alertController)
            return
        }
        
        self.sessionNotificationScheduler.didChangeSessionNotificationsSetting(enabled)
    }
}
