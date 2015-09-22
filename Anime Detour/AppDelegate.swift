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
    
    // MARK: - Notifications
    
    #if os(iOS)
    private var appWideNotificationPermissionsEnabled: Bool {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        return (settings?.types ?? .None) != .None
    }
    
    private lazy var sessionNotificationScheduler: SessionNotificationScheduler = {
        let context = self.primaryContext
        let scheduler = SessionNotificationScheduler(managedObjectContext: context)
        scheduler.delegate = self
        return scheduler
    }()
    
    private lazy var notificationPermissionRequester: NotificationPermissionRequester = NotificationPermissionRequester(internalSettings: self.internalSettings, sessionSettings: self.userVisibleSessionSettings)
    #endif
    
    // MARK: - Settings
    
    private let dataStatusDefaultsController: DataStatusDefaultsController = DataStatusDefaultsController()
    private let internalSettings: InternalSettings = InternalSettings()
    private let userVisibleSessionSettings: SessionSettings = SessionSettings()
    
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
        
        #if os(iOS)
        self.userVisibleSessionSettings.delegate = self
        #endif

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
        
        let dataStatusDefaultsController = self.dataStatusDefaultsController

        let guestsNeedClearing = guestsClearDate.timeIntervalSinceDate(dataStatusDefaultsController.lastGuestsClearDate) > 0
        let sessionsNeedClearing = sessionsClearDate.timeIntervalSinceDate(dataStatusDefaultsController.lastSessionsClearDate) > 0
        if guestsNeedClearing || sessionsNeedClearing {
            self.coreDataController.clearPersistentStore()

            // Clearing the persistent store removes all sessions and guests, since they are both kept
            // in the same store, so we need to fetch them again.
            dataStatusDefaultsController.guestsFetchRequired = true
            dataStatusDefaultsController.sessionsFetchRequired = true
        }

        if dataStatusDefaultsController.sessionsFetchRequired {
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

        if dataStatusDefaultsController.guestsFetchRequired {
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
                        dataStatusDefaultsController.guestsFetchRequired = false
                        dataStatusDefaultsController.lastGuestsClearDate = NSDate()

                        dataStatusDefaultsController.synchronizeDefaults()
                    } catch {
                        let error = error
                        NSLog("Error saving guests: \(error)")
                    }
                }
            }
        }

        return true
    }
    
    #if os(iOS)
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        let localNotificationsAllowed: Bool
        if notificationSettings.types == .None {
            localNotificationsAllowed = false
        } else {
            localNotificationsAllowed = true
        }
        self.localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    #endif
    
    func applicationDidBecomeActive(application: UIApplication) {
        #if os(iOS)
        self.checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled()
        #endif
    }
    
    // MARK: - Presenting Alerts
    
    private func show(alertController: UIAlertController) {
        self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
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

// MARK: - Notifications
#if os(iOS)
extension AppDelegate {
    private func checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled() {
        let localNotificationsAllowed = self.appWideNotificationPermissionsEnabled
        self.localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    private func localNotificationsAllowedChanged(localNotificationsAllowed: Bool) {
        self.notificationPermissionRequester.localNotificationsAllowed = localNotificationsAllowed
        self.updateSessionNotificationsEnabled(localNotificationsAllowed)
    }
    
    /**
    Update the Session notification scheduler's notifications enabled setting
    based on our user visible settings' setting.
    */
    private func updateSessionNotificationsEnabled(localNotificationsAllowed: Bool) {
        let enabledInUserPref = self.userVisibleSessionSettings.favoriteSessionAlerts
        self.sessionNotificationScheduler.notificationsEnabled = localNotificationsAllowed && enabledInUserPref
    }
}

// MARK: - NotificationPermissionRequesterDelegate
extension AppDelegate: NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(requester: NotificationPermissionRequester, wantsToPresentAlertController alertController: UIAlertController) {
        self.show(alertController)
    }
}

// MARK: - SessionFavoriteNotificationDelegate
extension AppDelegate: SessionFavoriteNotificationDelegate {
    func didChangeFavoriteSessions(count: Int) {
        if !self.internalSettings.askedToEnableNotifications && !self.userVisibleSessionSettings.favoriteSessionAlerts {
            self.notificationPermissionRequester.enableSessionNotificationsOnNotificationsEnabled = true
            self.notificationPermissionRequester.askEnableSessionNotifications()
        }
    }
}

// MARK: - SessionSettingsDelegate
extension AppDelegate: SessionSettingsDelegate {
    func didChangeSessionNotificationsSetting(enabled: Bool) {
        guard enabled else {
            self.sessionNotificationScheduler.didChangeSessionNotificationsSetting(enabled)
            return
        }
        
        guard self.internalSettings.askedToEnableNotifications else {
            self.notificationPermissionRequester.askEnableSessionNotifications()
            return
        }
        
        guard self.internalSettings.askedSystemToEnableNotifications else {
            self.notificationPermissionRequester.requestNotificationPermissions()
            return
        }
        
        guard self.notificationPermissionRequester.localNotificationsAllowed else {
            // Disable the notification setting if notifications are not allowed
            self.userVisibleSessionSettings.favoriteSessionAlerts = false
            
            let alertController = UIAlertController(title: "Enable Notifications", message: "Enable notifications in the Settings app before enabling session alerts.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let settings = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
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
#endif
