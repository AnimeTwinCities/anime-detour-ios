//
//  AppDelegate.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import CoreData
import AnimeDetourDataModel
import AnimeDetourAPI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var persistentContainer: NSPersistentContainer {
        return shared.persistentContainer
    }
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var window: UIWindow?

    lazy private(set) var apiClient = AnimeDetourAPIClient.sharedInstance
    lazy private(set) var persistentContainer = AppDelegate.createPersistentContainer()
    
    private let firebaseCoordinator = FirebaseCoordinator()
    
    // MARK: - Notifications
    
    #if os(iOS)
    fileprivate var appWideNotificationPermissionsEnabled: Bool {
        let settings = UIApplication.shared.currentUserNotificationSettings
        return !(settings?.types == .none)
    }
    
    fileprivate lazy var sessionNotificationScheduler: SessionNotificationScheduler = {
        let context = self.persistentContainer.viewContext
        let scheduler = SessionNotificationScheduler(managedObjectContext: context)
        scheduler.delegate = self
        return scheduler
    }()
    
    fileprivate lazy var notificationPermissionRequester: NotificationPermissionRequester = NotificationPermissionRequester(internalSettings: self.internalSettings, sessionSettings: self.userVisibleSessionSettings)
    #endif
    
    // MARK: - Settings
    
    fileprivate let dataStatusDefaultsController: DataStatusDefaultsController = DataStatusDefaultsController()
    fileprivate let internalSettings: InternalSettings = InternalSettings()
    fileprivate let userVisibleSessionSettings: SessionSettings = SessionSettings()
    
    // MARK: - Updates Cleanup
    
    fileprivate lazy var previousDataCleaner: PreviousDataCleaner = PreviousDataCleaner()
    
    // MARK: - Application Delegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
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
        _ = persistentContainer

        // Latest must-be-cleared dates, e.g. if this version of the app points
        // at a different data set and must discard and re-download data.
        var calendar = Calendar.current
        let timezone = TimeZone(identifier: "America/Chicago")!
        calendar.timeZone = timezone
        var components = DateComponents()
        components.day = 21
        components.month = 3
        components.year = 2016
        let guestsClearDate = calendar.date(from: components)!
        let sessionsClearDate = calendar.date(from: components)!
        
        checkAndHandleDatabase()

        let guestsNeedClearing = guestsClearDate.timeIntervalSince(dataStatusDefaultsController.lastGuestsClearDate as Date) > 0
        let sessionsNeedClearing = sessionsClearDate.timeIntervalSince(dataStatusDefaultsController.lastSessionsClearDate as Date) > 0
        if guestsNeedClearing || sessionsNeedClearing {
            dataStatusDefaultsController.lastGuestsClearDate = Date()
            dataStatusDefaultsController.lastSessionsClearDate = Date()
            // clear the database
            persistentContainer.performBackgroundTask { context in
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
                let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                _ = try? context.execute(batchRequest)
            }

            // Clearing the persistent store removes all sessions and guests, since they are both kept
            // in the same store, so we need to fetch them again.
            dataStatusDefaultsController.guestsFetchRequired = true
            dataStatusDefaultsController.sessionsFetchRequired = true
        }

        persistentContainer.performBackgroundTask { [apiClient, dataStatusDefaultsController] backgroundContext in
            if dataStatusDefaultsController.sessionsFetchRequired {
                apiClient.fetchSessions(dataStatusDefaultsController, managedObjectContext: backgroundContext)
            }
            
            if dataStatusDefaultsController.guestsFetchRequired {
                apiClient.fetchGuests(dataStatusDefaultsController, managedObjectContext: backgroundContext)
            }
        }
        
        firebaseCoordinator.start()
        
        return true
    }
    
    #if os(iOS)
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        let localNotificationsAllowed: Bool
        if notificationSettings.types == UIUserNotificationType() {
            localNotificationsAllowed = false
        } else {
            localNotificationsAllowed = true
        }
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        let alert = UIAlertController(title: notification.alertTitle ?? "Favorite Starting Soon", message: notification.alertBody, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Got It", style: .default, handler: { [weak alert] _ in alert?.dismiss(animated: true, completion: nil) })
        alert.addAction(dismiss)
    
        show(alert)
    }
    #endif
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        #if os(iOS)
        checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled()
        #endif
    }
    
    // MARK: - Handoff
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
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
    fileprivate func initAnalytics() {
        let analytics = GAI.sharedInstance()
        analytics?.dispatchInterval = 30 // seconds
        guard let file = Bundle.main.path(forResource: "GoogleAnalyticsConfiguration", ofType: "plist"),
            let analyticsDictionary = NSDictionary(contentsOfFile: file),
            let analyticsID = analyticsDictionary["analyticsID"] as? String else {
                return
        }
        
        if let tracker = analytics?.tracker(withTrackingId: analyticsID) {
            UIViewController.hookViewDidAppearForAnalytics(tracker)
        }
    }
    
    // MARK: - Presenting Alerts
    
    fileprivate func show(_ alertController: UIAlertController) {
        let presenter = window?.rootViewController?.presentedViewController ?? window?.rootViewController
        presenter?.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Core Data
    
    fileprivate func checkAndHandleDatabase() {
        let twentysixteenOrOlderDatabaseNeedsClearing: Bool
        
        let lastCheckedVersion = dataStatusDefaultsController.databaseCheckedVersionKey
        switch "2017".compare(lastCheckedVersion, options: .numeric, range: nil, locale: nil) {
        case ComparisonResult.orderedDescending:
            twentysixteenOrOlderDatabaseNeedsClearing = true
        default:
            twentysixteenOrOlderDatabaseNeedsClearing = false
        }
        
        if twentysixteenOrOlderDatabaseNeedsClearing {
            previousDataCleaner.clean2Dot1And2016Dot1Databases()
        }
        
        let currentVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        dataStatusDefaultsController.databaseCheckedVersionKey = currentVersionNumber
    }
    
    // MARK: - Settings
    
    @objc fileprivate func showSettings() {
        let application = UIApplication.shared
        application.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    // MARK: - Theming

    /**
    Set basic color theme for the app.
    */
    fileprivate func setColors(_ application: UIApplication) {
        let mainColor = UIColor.adr_orange

        window?.tintColor = mainColor
        
        // Setup the appearance of age requirement labels
        AgeRequirementAwakeFromNibHook.hookAwakeFromNibForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetHighlightedForAgeLabelAppearance()
        AgeRequirementAwakeFromNibHook.hookTableViewCellSetSelectedForAgeLabelAppearance()
        
        // Make UISearchBars minimal style but with gray text fields by default
        let searchBar = UISearchBar.appearance()
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = UIColor.adr_lightGray
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.gray
                
        let tableViewBackgroundView = UIView()
        tableViewBackgroundView.backgroundColor = UIColor.adr_lighterOrange
        UITableViewCell.appearance().selectedBackgroundView = tableViewBackgroundView
        GuestCollectionViewCell.appearance().highlightColor = UIColor.adr_lighterOrange
        SessionCollectionViewCell.appearance().highlightColor = UIColor.adr_lighterOrange
        TextHeaderCollectionReusableView.appearance().backgroundColor = UIColor.adr_lightGray
    }
}

private class PreviousDataCleaner {
    func clean2Dot1And2016Dot1Databases() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentsURL = urls.first else {
            return
        }
        
        let storeFilenames = ["ConScheduleData", "AnimeDetour"]
        let storeExtensions = ["sqlite", "sqlite-shm", "sqlite-wal"]
        
        let storeFileURLs = storeFilenames.flatMap { filename in
            storeExtensions.map({ "\(filename).\($0)" }).map(documentsURL.appendingPathComponent(_:))
        }
        for url in storeFileURLs {
            _ = try? fileManager.removeItem(at: url)
        }
    }
}

fileprivate extension AppDelegate {
    static func createPersistentContainer() -> NSPersistentContainer {
        guard let momLocation = Bundle(for: Session.self).url(forResource: "AnimeDetourDataModel", withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOf: momLocation) else {
                fatalError("Couldn't find CoreData model.")
        }
        
        let container = NSPersistentContainer(name: "AnimeDetour", managedObjectModel: mom)
        if let seedDataURL = Bundle.main.url(forResource: "AnimeDetourDataModel", withExtension: "sqlite") {
            let defaultLocation = NSPersistentContainer.defaultDirectoryURL()
            let destination = URL(fileURLWithPath: "AnimeDetour.sqlite", relativeTo: defaultLocation)
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: destination.path) {
                do {
                    try fileManager.copyItem(at: seedDataURL, to: destination)
                    let dataStatusDefaultsController = DataStatusDefaultsController()
                    dataStatusDefaultsController.guestsFetchRequired = false
                    dataStatusDefaultsController.sessionsFetchRequired = false
                } catch {
                    NSLog("Error copying seed data: %@", error as NSError)
                }
            }
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        
        return container
    }
}

// MARK: - Notifications
#if os(iOS)
extension AppDelegate {
    fileprivate func checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled() {
        let localNotificationsAllowed = appWideNotificationPermissionsEnabled
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    fileprivate func localNotificationsAllowedChanged(_ localNotificationsAllowed: Bool) {
        notificationPermissionRequester.localNotificationsAllowed = localNotificationsAllowed
        updateSessionNotificationsEnabled(localNotificationsAllowed)
    }
    
    /**
    Update the Session notification scheduler's notifications enabled setting
    based on our user visible settings' setting.
    */
    fileprivate func updateSessionNotificationsEnabled(_ localNotificationsAllowed: Bool) {
        let enabledInUserPref = userVisibleSessionSettings.favoriteSessionAlerts
        sessionNotificationScheduler.notificationsEnabled = localNotificationsAllowed && enabledInUserPref
    }
}

// MARK: - NotificationPermissionRequesterDelegate
extension AppDelegate: NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(_ requester: NotificationPermissionRequester, wantsToPresentAlertController alertController: UIAlertController) {
        show(alertController)
    }
}

// MARK: - SessionFavoriteNotificationDelegate
extension AppDelegate: SessionFavoriteNotificationDelegate {
    func didChangeFavoriteSessions(_ count: Int) {
        guard !internalSettings.askedToEnableNotifications && !userVisibleSessionSettings.favoriteSessionAlerts else {
            return
        }
        
        notificationPermissionRequester.enableSessionNotificationsOnNotificationsEnabled = true
        notificationPermissionRequester.askEnableSessionNotifications()
    }
}

// MARK: - SessionSettingsDelegate
extension AppDelegate: SessionSettingsDelegate {
    func didChangeSessionNotificationsSetting(_ enabled: Bool) {
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
            
            let alertController = UIAlertController(title: "Enable Notifications", message: "Enable notifications in the Settings app before enabling session alerts.", preferredStyle: UIAlertControllerStyle.alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let settings = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
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
