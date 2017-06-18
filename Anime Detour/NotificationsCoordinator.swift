//
//  NotificationsCoordinator.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/11/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation
import UserNotifications

protocol NotificationsCoordinatorDelegate: class {
    func show(_ alert: UIAlertController)
    func showSettings()
}

final class NotificationsCoordinator {
    let internalSettings: InternalSettings
    let sessionSettings: SessionSettings
    
    var sessionDataSource: (SessionDataSource & SessionStarsDataSource)? {
        didSet {            
            sessionDataSource?.sessionDataSourceDelegate = self
            sessionDataSource?.sessionStarsDataSourceDelegate = self
            
            guard let dataSource = sessionDataSource else {
                sessionNotificationScheduler = nil
                return
            }
            
            sessionNotificationScheduler = SessionNotificationScheduler(dataSource: dataSource)
        }
    }
    
    weak var delegate: NotificationsCoordinatorDelegate?
    
    /**
     An NSObject subclass we use to receive messages from UNUserNotificationCenter.
     */
    fileprivate let notificationCenterDelegate = NotificationCenterDelegate()
    
    /**
     The object we use to ask the user for permission to use notifications.
     */
    fileprivate lazy var permissionRequester: NotificationPermissionRequester = NotificationPermissionRequester(internalSettings: self.internalSettings, sessionSettings: self.sessionSettings)
    
    /**
     Scheduler that monitors for starred sessions and schedules notifications for those sessions.
     */
    fileprivate var sessionNotificationScheduler: SessionNotificationScheduler?
    
    init(internalSettings: InternalSettings, sessionSettings: SessionSettings) {
        self.internalSettings = internalSettings
        self.sessionSettings = sessionSettings
    }
    
    func start() {
        UNUserNotificationCenter.current().delegate = notificationCenterDelegate
        permissionRequester.delegate = self
    }
    
    func didBecomeActive() {
        checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled()
    }
    
    func didChangeSessionNotificationsSetting(_ enabled: Bool) {
        guard enabled else {
            sessionNotificationScheduler?.didChangeSessionNotificationsSetting(enabled)
            return
        }
        
        guard internalSettings.askedToEnableNotifications else {
            permissionRequester.askEnableSessionNotifications(completionHandler: permissionRequestCompletionHandler)
            return
        }
        
        guard internalSettings.askedSystemToEnableNotifications else {
            permissionRequester.requestNotificationPermissions(completionHandler: permissionRequestCompletionHandler)
            return
        }
        
        guard permissionRequester.localNotificationsAllowed else {
            // Disable the notification setting if notifications are not allowed
            sessionSettings.favoriteSessionAlerts = false
            
            let alertController = UIAlertController(title: "Enable Notifications", message: "Enable notifications in the Settings app before enabling session alerts.", preferredStyle: UIAlertControllerStyle.alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            let settings = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) -> Void in
                self.delegate?.showSettings()
                return
            })
            
            alertController.addAction(cancel)
            alertController.addAction(settings)
            
            delegate?.show(alertController)
            return
        }
        
        sessionNotificationScheduler?.didChangeSessionNotificationsSetting(enabled)
    }
}

private extension NotificationsCoordinator {
    func checkAppAllowedToSendNotificationsAndUpdateSessionNotificationsEnabled() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            let localNotificationsAllowed = settings.authorizationStatus == .authorized
            self.localNotificationsAllowedChanged(localNotificationsAllowed)
        }
    }
    
    func localNotificationsAllowedChanged(_ localNotificationsAllowed: Bool) {
        permissionRequester.localNotificationsAllowed = localNotificationsAllowed
        updateSessionNotificationsEnabled(localNotificationsAllowed)
    }
    
    func didChangeFavoriteSessions() {
        guard !(sessionDataSource?.allSessions(limit: 1).isEmpty ?? true) else {
            return
        }
        
        guard !internalSettings.askedToEnableNotifications && !sessionSettings.favoriteSessionAlerts else {
            return
        }
        
        permissionRequester.enableSessionNotificationsOnNotificationsEnabled = true
        permissionRequester.askEnableSessionNotifications(completionHandler: permissionRequestCompletionHandler)
    }
    
    /**
     Update the Session notification scheduler's notifications enabled setting
     based on our user visible settings' setting.
     */
    func updateSessionNotificationsEnabled(_ localNotificationsAllowed: Bool) {
        let enabledInUserPref = sessionSettings.favoriteSessionAlerts
        sessionNotificationScheduler?.notificationsEnabled = localNotificationsAllowed && enabledInUserPref
    }
    
    func permissionRequestCompletionHandler(isGranted: Bool, error: Error?) {
        localNotificationsAllowedChanged(isGranted)
    }
}

extension NotificationsCoordinator: SessionDataSourceDelegate, SessionStarsDataSourceDelegate {
    func sessionDataSourceDidUpdate(filtering: Bool) {
        didChangeFavoriteSessions()
        sessionNotificationScheduler?.updateScheduledNotifications()
    }
    
    func sessionStarsDidUpdate(dataSource: SessionStarsDataSource) {
        didChangeFavoriteSessions()
        sessionNotificationScheduler?.updateScheduledNotifications()
    }
}

// MARK: - NotificationPermissionRequesterDelegate
extension NotificationsCoordinator: NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(_ requester: NotificationPermissionRequester, wantsToPresentAlertController alertController: UIAlertController) {
        delegate?.show(alertController)
    }
}

private extension NotificationsCoordinator {
    final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .sound])
        }
    }
}
