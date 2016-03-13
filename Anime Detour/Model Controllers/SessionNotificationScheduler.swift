//
//  SessionNotificationScheduler.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/19/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import CoreData
import AnimeDetourDataModel

/**
 Schedules local notifications for favorite Sessions.
 */
class SessionNotificationScheduler: NSObject, NSFetchedResultsControllerDelegate, SessionSettingsDelegate {
    let managedObjectContext: NSManagedObjectContext
    let fetchedResultsController: NSFetchedResultsController
    
    /// Enable/disable the setting of notifications.
    var notificationsEnabled: Bool = false {
        didSet {
            updateScheduledNotifications()
        }
    }
    
    weak var delegate: SessionFavoriteNotificationDelegate?
    
    /**
     Designated initializer.
     
     - parameter managedObjectContext: A context. Note that saves on other contexts must be merged
     into this context, or changes to Session favorite status may not be picked up.
    */
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: Session.entityName)
        let predicate = NSPredicate(format: "%K == true", "bookmarked")
        fetchRequest.predicate = predicate
        let startKey = "start"
        let nameKey = "name"
        let sorts = [ NSSortDescriptor(key: startKey, ascending: true), NSSortDescriptor(key: nameKey, ascending: true) ]
        fetchRequest.sortDescriptors = sorts
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: startKey, cacheName: nil)
        fetchedResultsController = frc
        
        super.init()
        
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            let error = error as NSError
            assertionFailure("Failed to fetch sessions: \(error)")
        }
        
        updateScheduledNotifications()
    }
    
    /// Schedule local notifications, one per time for which a favorite Session starts.
    private func scheduleNotifications(sessionFetchedResultsController: NSFetchedResultsController) {
        let application = UIApplication.sharedApplication()
        
        let timeToStart = "10 minutes"
        
        guard notificationsEnabled else {
            unscheduleNotifications()
            return
        }
        
        guard let sections = sessionFetchedResultsController.sections else {
            return
        }
        
        let nonEmptyfutureSections = sections.filter { section in
            guard let sessions = section.objects as? [Session] else {
                assertionFailure("Unexpected object type found in section: \(section)")
                return false
            }
            
            guard let firstSession = sessions.first else {
                assertionFailure("Unexpected empty section found: \(section)")
                return false
            }
            
            // Avoid scheduling notifications for events in the past
            let now = NSDate()
            if firstSession.start.timeIntervalSinceDate(now) >= 0 {
                return true
            } else {
                return false
            }
        }
        
        let notifications = nonEmptyfutureSections.map { section -> UILocalNotification in
            let numberSessionsAtTime = section.numberOfObjects
            
            // We know that all sections that made it past `filter`
            // have [Session]s with at least one object.
            let sessions = section.objects as! [Session]
            let firstSession = sessions.first!
            
            let notification = notificationFor(firstSession)
            var alertBody: String
            if numberSessionsAtTime > 1 {
                alertBody = "\(numberSessionsAtTime) favorite sessions starting in \(timeToStart)."
            } else {
                let sessionName = firstSession.name
                var displayName = sessionName
                let maxNameLength = 20
                if sessionName.characters.count > maxNameLength {
                    displayName = sessionName.substringToIndex(displayName.startIndex.advancedBy(maxNameLength)) + "..."
                }
                
                let location = firstSession.room
                alertBody = "\(displayName) starting in \(timeToStart) at \(location)."
            }
            
            notification.alertBody = alertBody
            
            let noteInfo = SessionNotificationInfo(sessions: sessions)
            notification.userInfo = noteInfo.toUserInfo()
            return notification
        }
        
        for note in notifications {
            application.scheduleLocalNotification(note)
        }
    }
    
    /// Create a local notification with our standard fire time, for a favorite session.
    private func notificationFor(session: Session) -> UILocalNotification {
        let notification = UILocalNotification()
        
        let tenMinutes: NSTimeInterval = 10 * 60 // 10 minutes * 60 seconds
        let sessionStart = session.start
        let tenMinutesBefore = sessionStart.dateByAddingTimeInterval(-tenMinutes)
        notification.fireDate = tenMinutesBefore
        
        return notification
    }
    
    /// Unschedule all of the local notifications that any instances of this class may have created.
    private func unscheduleNotifications() {
        let application = UIApplication.sharedApplication()
        
        guard let allLocalNotifications = application.scheduledLocalNotifications else {
            return
        }
        
        let sessionNotifications = allLocalNotifications.filter { note in
            guard let userInfo = note.userInfo else { return false }
            
            if let _ = SessionNotificationInfo(userInfo: userInfo) {
                return true
            } else {
                return false
            }
        }
        
        for note in sessionNotifications {
            application.cancelLocalNotification(note)
        }
    }
    
    /// Update all scheduled local notifications to match the current set of favorite Sessions.
    private func updateScheduledNotifications() {
        // Always remove any existing notifications that we scheduled
        unscheduleNotifications()
        
        if notificationsEnabled {
            scheduleNotifications(fetchedResultsController)
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let count = controller.fetchedObjects!.reduce(0, combine: { (count, object) in
            if (object as! Session).bookmarked {
                return count + 1
            } else {
                return count
            }
        })
        
        delegate?.didChangeFavoriteSessions(count)
        updateScheduledNotifications()
    }
    
    // MARK: - User Visible Settings Delegate
    
    func didChangeSessionNotificationsSetting(enabled: Bool) {
        notificationsEnabled = enabled
        
        // Track notifications getting enabled/disabled
        if let analytics = GAI.sharedInstance().defaultTracker {
            let dict = GAIDictionaryBuilder.createEventDictionary(.Settings, action: .Notifications, label: nil, value: NSNumber(integer: enabled ? 1 : 0))
            analytics.send(dict)
        }
    }
}

protocol SessionFavoriteNotificationDelegate: class {
    func didChangeFavoriteSessions(count: Int)
}

private struct SessionNotificationInfo {
    let sessionIDs: [String]
    
    init(sessions: [Session]) {
        sessionIDs = sessions.map { return $0.sessionID }
    }
    
    init?(userInfo: [NSObject : AnyObject]) {
        if let sessionIDs = userInfo["sessionIDs"] as? [String] {
            self.sessionIDs = sessionIDs
        } else {
            return nil
        }
    }
    
    func toUserInfo() -> [NSObject : AnyObject] {
        return ["sessionIDs" : sessionIDs]
    }
}
