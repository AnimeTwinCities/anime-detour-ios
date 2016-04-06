//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import AnimeDetourDataModel
import AnimeDetourAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var apiClient = AnimeDetourAPIClient.sharedInstance
    lazy var coreDataController = CoreDataController.sharedInstance
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.coreDataController.createManagedObjectContext(.PrivateQueueConcurrencyType)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.updateMainContextFor(saveNotification:)), name: NSManagedObjectContextDidSaveNotification, object: context)
        return context
    }()
    lazy var primaryContext: NSManagedObjectContext = {
        return self.coreDataController.managedObjectContext
    }()
    
    // MARK: - Notifications
    
    #if os(iOS)
    private var appWideNotificationPermissionsEnabled: Bool {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        return !(settings?.types == .None)
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
    
    // MARK: - Updates Cleanup
    
    private lazy var previousDataCleaner: PreviousDataCleaner = PreviousDataCleaner()
    
    // MARK: - Application Delegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        setColors(application)
        
        #if DEBUG
            // no analytics
        #else
            initAnalytics()
        #endif
        
        #if os(iOS)
            notificationPermissionRequester.delegate = self
            userVisibleSessionSettings.delegate = self
        #endif
        
        // Force initialization of our database before doing anything with data
        _ = coreDataController

        // Latest must-be-cleared dates, e.g. if this version of the app points
        // at a different data set and must discard and re-download data.
        let calendar = NSCalendar.currentCalendar()
        let timezone = NSTimeZone(name: "America/Chicago")!
        calendar.timeZone = timezone
        let components = NSDateComponents()
        components.day = 21
        components.month = 3
        components.year = 2016
        let guestsClearDate = calendar.dateFromComponents(components)!
        let sessionsClearDate = calendar.dateFromComponents(components)!
        
        checkAndHandleDatabase()

        let guestsNeedClearing = guestsClearDate.timeIntervalSinceDate(dataStatusDefaultsController.lastGuestsClearDate) > 0
        let sessionsNeedClearing = sessionsClearDate.timeIntervalSinceDate(dataStatusDefaultsController.lastSessionsClearDate) > 0
        if guestsNeedClearing || sessionsNeedClearing {
            dataStatusDefaultsController.lastGuestsClearDate = NSDate()
            dataStatusDefaultsController.lastSessionsClearDate = NSDate()
            coreDataController.clearPersistentStore()

            // Clearing the persistent store removes all sessions and guests, since they are both kept
            // in the same store, so we need to fetch them again.
            dataStatusDefaultsController.guestsFetchRequired = true
            dataStatusDefaultsController.sessionsFetchRequired = true
        }

        if dataStatusDefaultsController.sessionsFetchRequired {
            apiClient.fetchSessions(dataStatusDefaultsController, managedObjectContext: backgroundContext)
        }

        if dataStatusDefaultsController.guestsFetchRequired {
            apiClient.fetchGuests(dataStatusDefaultsController, managedObjectContext: backgroundContext)
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
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        let alert = UIAlertController(title: notification.alertTitle ?? "Favorite Starting Soon", message: notification.alertBody, preferredStyle: .Alert)
        let dismiss = UIAlertAction(title: "Got It", style: .Default, handler: { [weak alert] _ in alert?.dismissViewControllerAnimated(true, completion: nil) })
        alert.addAction(dismiss)
    
        show(alert)
    }
    #endif
    
    func applicationDidBecomeActive(application: UIApplication) {
        #if os(iOS)
        checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled()
        #endif
    }
    
    // MARK: - Handoff
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        let tabBarController = window?.rootViewController as? UITabBarController
        if let activityController = tabBarController.map({ UserActivityController(tabBarController: $0) }) {
            restorationHandler([activityController])
        }
        
        return true
    }
    
    // MARK: - Analytics
    
    /**
     Setup analytics tracking.
     */
    private func initAnalytics() {
        let analytics = GAI.sharedInstance()
        analytics.dispatchInterval = 30 // seconds
        guard let file = NSBundle.mainBundle().pathForResource("GoogleAnalyticsConfiguration", ofType: "plist"),
            let analyticsDictionary = NSDictionary(contentsOfFile: file),
            let analyticsID = analyticsDictionary["analyticsID"] as? String else {
                return
        }
        
        let tracker = analytics.trackerWithTrackingId(analyticsID)
        
        UIViewController.hookViewDidAppearForAnalytics(tracker)
    }
    
    // MARK: - Presenting Alerts
    
    private func show(alertController: UIAlertController) {
        let presenter = window?.rootViewController?.presentedViewController ?? window?.rootViewController
        presenter?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Core Data
    
    /**
    Merge changes from a save notification into the primary, main thread-only MOC.
    */
    @objc(updateMainContextForSaveNotification:) private func updateMainContextFor(saveNotification notification: NSNotification) {
        primaryContext.performBlock {
            self.primaryContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
    private func checkAndHandleDatabase() {
        let twoDotOneDatabaseNeedsClearing: Bool
        
        switch dataStatusDefaultsController.databaseCheckedVersionKey.compare("2.1", options: .NumericSearch, range: nil, locale: nil) {
        case .OrderedAscending, .OrderedSame:
            twoDotOneDatabaseNeedsClearing = true
        case .OrderedDescending:
            twoDotOneDatabaseNeedsClearing = false
        }
        if twoDotOneDatabaseNeedsClearing {
            previousDataCleaner.cleanTwoDotOneDatabase()
        }
        
        let currentVersionNumber = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as! String
        dataStatusDefaultsController.databaseCheckedVersionKey = currentVersionNumber
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

        window?.tintColor = mainColor
        
        // Setup the appearance of age requirement labels
        AgeRequirementAwakeFromNibHook.hookAwakeFromNibForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetHighlightedForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetSelectedForAgeLabelAppearance()
        
        // Make UISearchBars minimal style but with gray text fields by default
        let searchBar = UISearchBar.appearance()
        searchBar.searchBarStyle = .Minimal
        searchBar.backgroundColor = UIColor.adr_lightGray
        UITextField.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).backgroundColor = UIColor.grayColor()
                
        let tableViewBackgroundView = UIView()
        tableViewBackgroundView.backgroundColor = UIColor.adr_lighterOrange
        UITableViewCell.appearance().selectedBackgroundView = tableViewBackgroundView
        GuestCollectionViewCell.appearance().highlightColor = UIColor.adr_lighterOrange
        SessionCollectionViewCell.appearance().highlightColor = UIColor.adr_lighterOrange
        TextHeaderCollectionReusableView.appearance().backgroundColor = UIColor.adr_lightGray
    }
}

private class PreviousDataCleaner {
    func cleanTwoDotOneDatabase() {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        guard let documentsURL = urls.first else {
            return
        }
        
        let storeFilename = "ConScheduleData"
        let storeExtensions = ["sqlite", "sqlite-shm", "sqlite-wal"]
        
        let storeFileURLs = storeExtensions.map({ "\(storeFilename).\($0)" }).map(documentsURL.URLByAppendingPathComponent)
        for url in storeFileURLs {
            _ = try? fileManager.removeItemAtURL(url)
        }
    }
}

// MARK: - Notifications
#if os(iOS)
extension AppDelegate {
    private func checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled() {
        let localNotificationsAllowed = appWideNotificationPermissionsEnabled
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    private func localNotificationsAllowedChanged(localNotificationsAllowed: Bool) {
        notificationPermissionRequester.localNotificationsAllowed = localNotificationsAllowed
        updateSessionNotificationsEnabled(localNotificationsAllowed)
    }
    
    /**
    Update the Session notification scheduler's notifications enabled setting
    based on our user visible settings' setting.
    */
    private func updateSessionNotificationsEnabled(localNotificationsAllowed: Bool) {
        let enabledInUserPref = userVisibleSessionSettings.favoriteSessionAlerts
        sessionNotificationScheduler.notificationsEnabled = localNotificationsAllowed && enabledInUserPref
    }
}

// MARK: - NotificationPermissionRequesterDelegate
extension AppDelegate: NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(requester: NotificationPermissionRequester, wantsToPresentAlertController alertController: UIAlertController) {
        show(alertController)
    }
}

// MARK: - SessionFavoriteNotificationDelegate
extension AppDelegate: SessionFavoriteNotificationDelegate {
    func didChangeFavoriteSessions(count: Int) {
        guard !internalSettings.askedToEnableNotifications && !userVisibleSessionSettings.favoriteSessionAlerts else {
            return
        }
        
        notificationPermissionRequester.enableSessionNotificationsOnNotificationsEnabled = true
        notificationPermissionRequester.askEnableSessionNotifications()
    }
}

// MARK: - SessionSettingsDelegate
extension AppDelegate: SessionSettingsDelegate {
    func didChangeSessionNotificationsSetting(enabled: Bool) {
        guard enabled else {
            sessionNotificationScheduler.didChangeSessionNotificationsSetting(enabled)
            return
        }
        
        guard internalSettings.askedToEnableNotifications else {
            notificationPermissionRequester.askEnableSessionNotifications()
            return
        }
        
        guard internalSettings.askedSystemToEnableNotifications else {
            notificationPermissionRequester.requestNotificationPermissions()
            return
        }
        
        guard notificationPermissionRequester.localNotificationsAllowed else {
            // Disable the notification setting if notifications are not allowed
            userVisibleSessionSettings.favoriteSessionAlerts = false
            
            let alertController = UIAlertController(title: "Enable Notifications", message: "Enable notifications in the Settings app before enabling session alerts.", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let settings = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.showSettings()
                return
            })
            
            alertController.addAction(cancel)
            alertController.addAction(settings)
            
            show(alertController)
            return
        }
        
        sessionNotificationScheduler.didChangeSessionNotificationsSetting(enabled)
    }
}
#endif
