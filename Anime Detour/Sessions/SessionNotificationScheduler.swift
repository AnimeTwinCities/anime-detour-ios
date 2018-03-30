//
//  SessionNotificationScheduler.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/19/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation
import UserNotifications
import os

/**
 Schedules local notifications for SessionsViewModels.
 */
class SessionNotificationScheduler: NSObject, SessionSettingsDelegate {
    /// Identifier for all session starting notifications that we create
    private static let SessionNotificationIdentifier = "SessionNotificationSchedulerNotificationIdentifier"
    
    /// How much time before a session should its notification fire
    private static let NotificationTimeBeforeSession: TimeInterval = 10 * 60
    
    let dataSource: SessionDataSource
    
    /// Enable/disable the setting of notifications.
    var notificationsEnabled: Bool = false {
        didSet {
            updateScheduledNotifications()
        }
    }
    
    /**
     Designated initializer.
     
     - parameter dataSource: A data source that only includes sessions for which notifications
     should be created.
    */
    init(dataSource: SessionDataSource) {
        self.dataSource = dataSource
        super.init()
        updateScheduledNotifications()
    }
    
    /// Update all scheduled local notifications to match the current set of favorite Sessions.
    func updateScheduledNotifications() {
        // Always remove any existing notifications that we scheduled
        unscheduleNotifications()
        
        guard !dataSource.allSessions(limit: 1).isEmpty else {
            return
        }
        
        if notificationsEnabled {
            scheduleNotifications(dataSource)
        }
    }
    
    /// Schedule local notifications, one per time for which a Session starts.
    fileprivate func scheduleNotifications(_ dataSource: SessionDataSource) {
        let timeToStart = NSLocalizedString("10 minutes", comment: "User-visible time before a session to present a notification")
        
        guard notificationsEnabled else {
            unscheduleNotifications()
            return
        }
        
        let futureSessions = dataSource.sections(startingAfter: Date())
        
        let notificationRequests = futureSessions.compactMap { (start, sectionInfo) -> UNNotificationRequest? in
            guard let fireDate = self.fireDate(forSessionAt: start) else {
                return nil
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.minute, .hour, .day, .month, .year], from: fireDate)
            let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let alertBody: String
            let onlySession: SessionViewModel?
            switch sectionInfo {
            case .count(let count):
                let multipleSessionsFormat = NSLocalizedString("%d favorite sessions starting in %@", comment: "")
                alertBody = String(format: multipleSessionsFormat, count, timeToStart)
                onlySession = nil
            case .first(let viewModel):
                let sessionName = viewModel.title
                var displayName = sessionName
                let maxNameLength = 20
                if displayName.count > maxNameLength {
                    displayName = sessionName.prefix(maxNameLength) + "…"
                }
                
                let singleSessionFormatWithLocation = NSLocalizedString("%@ starting in %@ at %@", comment: "")
                let singleSessionFormatWithoutLocation = NSLocalizedString("%@ starting in %@", comment: "")
                if let location = viewModel.room {
                    alertBody = String(format: singleSessionFormatWithLocation, displayName, timeToStart, location)
                } else {
                    alertBody = String(format: singleSessionFormatWithoutLocation, displayName, timeToStart)
                }
                onlySession = viewModel
            }
            
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = alertBody
            
            let noteInfo = SessionNotificationInfo(startTime: start, onlySession: onlySession)
            notificationContent.userInfo = noteInfo.toUserInfo()
            
            let request = UNNotificationRequest(identifier: SessionNotificationScheduler.SessionNotificationIdentifier, content: notificationContent, trigger: notificationTrigger)
            return request
        }
        
        let center = UNUserNotificationCenter.current()
        for request in notificationRequests {
            center.add(request) { maybeError in
                if let _ = maybeError {
                    os_log("Error trying to schedule a session notification.")
                }
            }
        }
    }
    
    /// Create a local notification with our standard fire time, for a session.
    /// `nil` indicates that no notification should be scheduled.
    fileprivate func fireDate(forSessionAt date: Date) -> Date? {
        guard date.timeIntervalSinceNow < -SessionNotificationScheduler.NotificationTimeBeforeSession else {
            return nil
        }
        
        let fireDate = date.addingTimeInterval(-SessionNotificationScheduler.NotificationTimeBeforeSession)
        return fireDate
    }
    
    /// Unschedule all of the local notifications that any instances of this class may have created.
    fileprivate func unscheduleNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [SessionNotificationScheduler.SessionNotificationIdentifier])
    }
    
    // MARK: - User Visible Settings Delegate
    
    func didChangeSessionNotificationsSetting(_ enabled: Bool) {
        notificationsEnabled = enabled
        
        // Track notifications getting enabled/disabled
        if let analytics = GAI.sharedInstance().defaultTracker {
            let dict = GAIDictionaryBuilder.createEventDictionary(.settings, action: .notifications, label: nil, value: NSNumber(value: enabled ? 1 : 0))
            analytics.send(dict)
        }
    }
}

protocol SessionFavoriteNotificationDelegate: class {
    func didChangeFavoriteSessions(_ count: Int)
}

private struct SessionNotificationInfo {
    let onlySessionID: String?
    let startTime: Date
    
    init(startTime: Date, onlySession: SessionViewModel?) {
        self.startTime = startTime
        self.onlySessionID = onlySession?.sessionID
    }
    
    init?(userInfo: [AnyHashable: Any]) {
        if let startTime = userInfo["startTime"] as? Date {
            self.startTime = startTime
            
            if let sessionID = userInfo["onlySessionID"] as? String {
                onlySessionID = sessionID
            } else {
                onlySessionID = nil
            }
        } else {
            return nil
        }
    }
    
    func toUserInfo() -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = ["startTime" : startTime]
        if let sessionID = onlySessionID {
            userInfo["sessionID"] = sessionID
        }
        
        return userInfo
    }
}
