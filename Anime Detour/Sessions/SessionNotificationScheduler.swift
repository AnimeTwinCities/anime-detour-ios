//
//  SessionNotificationScheduler.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/19/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

/**
 Schedules local notifications for SessionsViewModels.
 */
class SessionNotificationScheduler: NSObject, SessionSettingsDelegate {
    /// How much time before a session should its notification fire
    private static let timeBeforeSession: TimeInterval = 10 * 60
    
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
        let application = UIApplication.shared
        
        let timeToStart = "10 minutes"
        
        guard notificationsEnabled else {
            unscheduleNotifications()
            return
        }
        
        let futureSessions = dataSource.sections(startingAfter: Date())
        
        let notifications = futureSessions.flatMap { (start, sectionInfo) -> UILocalNotification? in
            let notification = UILocalNotification()
            guard let fireDate = self.fireDate(forSessionAt: start) else {
                return nil
            }
            notification.fireDate = fireDate
            
            let alertBody: String
            let onlySession: SessionViewModel?
            switch sectionInfo {
            case .count(let count):
                alertBody = "\(count) favorite sessions starting in \(timeToStart)."
                onlySession = nil
            case .first(let viewModel):
                let sessionName = viewModel.title
                var displayName = sessionName
                let maxNameLength = 20
                if displayName.characters.count > maxNameLength {
                    displayName = sessionName.substring(to: displayName.index(displayName.startIndex, offsetBy: maxNameLength)) + "..."
                }
                
                let location = viewModel.room
                alertBody = "\(displayName) starting in \(timeToStart) at \(location ?? "(no location)")."
                onlySession = viewModel
            }
            
            notification.alertBody = alertBody
            
            let noteInfo = SessionNotificationInfo(startTime: start, onlySession: onlySession)
            notification.userInfo = noteInfo.toUserInfo()
            return notification
        }
        
        for note in notifications {
            application.scheduleLocalNotification(note)
        }
    }
    
    /// Create a local notification with our standard fire time, for a session.
    /// `nil` indicates that no notification should be scheduled.
    fileprivate func fireDate(forSessionAt date: Date) -> Date? {
        guard date.timeIntervalSinceNow < -SessionNotificationScheduler.timeBeforeSession else {
            return nil
        }
        
        let fireDate = date.addingTimeInterval(-SessionNotificationScheduler.timeBeforeSession)
        return fireDate
    }
    
    /// Unschedule all of the local notifications that any instances of this class may have created.
    fileprivate func unscheduleNotifications() {
        let application = UIApplication.shared
        
        guard let allLocalNotifications = application.scheduledLocalNotifications else {
            return
        }
        
        let sessionNotifications = allLocalNotifications.filter { note in
            guard let userInfo = note.userInfo else { return false }
            
            if let _ = SessionNotificationInfo(userInfo: userInfo as [NSObject : AnyObject]) {
                return true
            } else {
                return false
            }
        }
        
        for note in sessionNotifications {
            application.cancelLocalNotification(note)
        }
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
