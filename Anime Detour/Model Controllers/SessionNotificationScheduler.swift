//
//  SessionNotificationScheduler.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/19/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import CoreData
import AnimeDetourAPI

/**
Schedules local notifications for favorite Sessions.
*/
class SessionNotificationScheduler: NSObject, NSFetchedResultsControllerDelegate, UserVisibleSettingsDelegate {
    let managedObjectContext: NSManagedObjectContext
    let fetchedResultsController: NSFetchedResultsController
    
    /// Enable/disable the setting of notifications.
    var notificationsEnabled: Bool = false {
        didSet {
            self.updateScheduledNotifications()
        }
    }
    
    weak var delegate: SessionFavoriteNotificationDelegate?
    
    /**
    Designated initializer.
    
    :param: managedObjectContext A context. Note that saves on other contexts must be merged
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
        self.fetchedResultsController = frc
        
        super.init()
        
        frc.delegate = self
        
        var fetchError: NSError?
        if !frc.performFetch(&fetchError) {
            if let error = fetchError {
                assertionFailure("Failed to fetch sessions: \(error)")
            } else {
                assertionFailure("Failed to fetch sessions with an unknown error")
            }
        }
        
        self.updateScheduledNotifications()
    }
    
    /// Schedule local notifications, one per time for which a favorite Session starts.
    private func scheduleNotifications(sessionFetchedResultsController: NSFetchedResultsController) {
        let application = UIApplication.sharedApplication()
        
        let timeToStart = "10 minutes"
        
        for section in sessionFetchedResultsController.sections as [NSFetchedResultsSectionInfo] {
            let numberSessionsAtTime = section.numberOfObjects
            
            let sessions = section.objects as [Session]
            let firstSession = sessions.first! // Assume each section has at least one Session
            
            // Avoid scheduling notifications for events in the past
            let now = NSDate()
            if firstSession.start.timeIntervalSinceDate(now) < 0 {
                continue
            }
            
            let notification = self.notification(firstSession)
            var alertBody: String
            if numberSessionsAtTime > 1 {
                alertBody = "\(numberSessionsAtTime) favorite sessions starting in \(timeToStart)."
            } else {
                let sessionName = firstSession.name
                var displayName = sessionName
                let maxNameLength = 20
                if countElements(sessionName) > maxNameLength {
                    displayName = sessionName.substringToIndex(advance(displayName.startIndex, maxNameLength)) + "..."
                }
                
                let location = firstSession.venue
                alertBody = "\(displayName) starting in \(timeToStart) at \(location)."
            }
            
            notification.alertBody = alertBody
            
            let noteInfo = SessionNotificationInfo(sessions: sessions)
            notification.userInfo = noteInfo.toUserInfo()
            application.scheduleLocalNotification(notification)
        }
        
        if !self.notificationsEnabled {
            self.unscheduleNotifications()
        }
    }
    
    /// Create a local notification with our standard fire time, for a favorite session.
    private func notification(session: Session) -> UILocalNotification {
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
        
        let allLocalNotifications = application.scheduledLocalNotifications as [UILocalNotification]
        let sessionNotifications = allLocalNotifications.filter { note in
            if let userInfo = note.userInfo {
                if let sessionNoteInfo = SessionNotificationInfo(userInfo: userInfo) {
                    return true
                }
            }
            return false
        }
        
        for note in sessionNotifications {
            application.cancelLocalNotification(note)
        }
    }
    
    /// Update all scheduled local notifications to match the current set of favorite Sessions.
    private func updateScheduledNotifications() {
        // Always remove any existing notifications that we scheduled
        self.unscheduleNotifications()
        
        if self.notificationsEnabled {
            self.scheduleNotifications(self.fetchedResultsController)
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        let count = controller.fetchedObjects!.reduce(0, combine: { (var count, object) in
            if (object as Session).bookmarked {
                return count + 1
            } else {
                return count
            }
        })
        
        self.delegate?.didChangeFavoriteSessions(count)
        self.updateScheduledNotifications()
    }
    
    // MARK: - User Visible Settings Delegate
    
    func didChangeSessionNotificationsSetting(enabled: Bool) {
        self.notificationsEnabled = enabled
    }
}

protocol SessionFavoriteNotificationDelegate: class {
    func didChangeFavoriteSessions(count: Int)
}

private struct SessionNotificationInfo {
    let sessionIDs: [String]
    
    init(sessions: [Session]) {
        self.sessionIDs = sessions.map { return $0.sessionID }
    }
    
    init?(userInfo: [NSObject : AnyObject]) {
        if let sessionIDs = userInfo["sessionIDs"] as? [String] {
            self.sessionIDs = sessionIDs
        } else {
            return nil
        }
    }
    
    func toUserInfo() -> [NSObject : AnyObject] {
        return ["sessionIDs" : self.sessionIDs]
    }
}
