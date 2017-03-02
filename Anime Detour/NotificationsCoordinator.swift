//
//  NotificationsCoordinator.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/11/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

protocol NotificationsCoordinatorDelegate: class {
    func show(_ alert: UIAlertController)
    func showSettings()
}

@available(iOS 10.0, *)
class NotificationsCoordinator {
    let internalSettings: InternalSettings
    let sessionSettings: SessionSettings
    
    var sessionDataSource: SessionDataSource? {
        didSet {
            guard let dataSource = sessionDataSource else {
                sessionNotificationScheduler = nil
                return
            }
            
            sessionNotificationScheduler = SessionNotificationScheduler(dataSource: dataSource)
            sessionNotificationScheduler?.delegate = self
        }
    }
    
    weak var delegate: NotificationsCoordinatorDelegate?
    
    fileprivate var appWideNotificationPermissionsEnabled: Bool {
        let settings = UIApplication.shared.currentUserNotificationSettings
        return !(settings?.types == .none)
    }
    
    fileprivate var sessionNotificationScheduler: SessionNotificationScheduler?
    
    fileprivate lazy var permissionRequester: NotificationPermissionRequester = NotificationPermissionRequester(internalSettings: self.internalSettings, sessionSettings: self.sessionSettings)
    
    init(internalSettings: InternalSettings, sessionSettings: SessionSettings) {
        self.internalSettings = internalSettings
        self.sessionSettings = sessionSettings
    }
    
    func start() {
        permissionRequester.delegate = self
    }
    
    func didRegister(with settings: UIUserNotificationSettings) {
        let localNotificationsAllowed: Bool
        if settings.types == UIUserNotificationType() {
            localNotificationsAllowed = false
        } else {
            localNotificationsAllowed = true
        }
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    func didReceive(notification: UILocalNotification) {
        let alert = UIAlertController(title: notification.alertTitle ?? "Favorite Starting Soon", message: notification.alertBody, preferredStyle: .alert)
        let dismiss = UIAlertAction(title: "Got It", style: .default, handler: { [weak alert] _ in alert?.dismiss(animated: true, completion: nil) })
        alert.addAction(dismiss)
        
        delegate?.show(alert)
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
            permissionRequester.askEnableSessionNotifications()
            return
        }
        
        guard internalSettings.askedSystemToEnableNotifications else {
            permissionRequester.requestNotificationPermissions()
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
        let localNotificationsAllowed = appWideNotificationPermissionsEnabled
        localNotificationsAllowedChanged(localNotificationsAllowed)
    }
    
    func localNotificationsAllowedChanged(_ localNotificationsAllowed: Bool) {
        permissionRequester.localNotificationsAllowed = localNotificationsAllowed
        updateSessionNotificationsEnabled(localNotificationsAllowed)
    }
    
    /**
     Update the Session notification scheduler's notifications enabled setting
     based on our user visible settings' setting.
     */
    func updateSessionNotificationsEnabled(_ localNotificationsAllowed: Bool) {
        let enabledInUserPref = sessionSettings.favoriteSessionAlerts
        sessionNotificationScheduler?.notificationsEnabled = localNotificationsAllowed && enabledInUserPref
    }
}

// MARK: - NotificationPermissionRequesterDelegate
extension NotificationsCoordinator: NotificationPermissionRequesterDelegate {
    func notificationPermissionRequester(_ requester: NotificationPermissionRequester, wantsToPresentAlertController alertController: UIAlertController) {
        delegate?.show(alertController)
    }
}

// MARK: - SessionFavoriteNotificationDelegate
extension NotificationsCoordinator: SessionFavoriteNotificationDelegate {
    func didChangeFavoriteSessions(_ count: Int) {
        guard !internalSettings.askedToEnableNotifications && !sessionSettings.favoriteSessionAlerts else {
            return
        }
        
        permissionRequester.enableSessionNotificationsOnNotificationsEnabled = true
        permissionRequester.askEnableSessionNotifications()
    }
}
