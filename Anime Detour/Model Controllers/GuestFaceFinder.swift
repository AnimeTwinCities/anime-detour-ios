//
//  GuestFaceFinder.swift
//  Anime Detour
//
//  Created by Brendon Justin on 12/11/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import CoreData
import AnimeDetourDataModel

class GuestFaceFinder {
    let faceDetector: ImageFaceDetector
    let managedObjectContext: NSManagedObjectContext
    let notificationCenter: NotificationCenter
    
    init(faceDetector: ImageFaceDetector, managedObjectContext: NSManagedObjectContext = AppDelegate.shared.persistentContainer.newBackgroundContext(), notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.faceDetector = faceDetector
        self.managedObjectContext = managedObjectContext
        self.notificationCenter = notificationCenter
        
        notificationCenter.addObserver(self, selector: #selector(objectsDidChange), name: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
    }
}

private extension GuestFaceFinder {
    @objc func objectsDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo, let changedObjects = userInfo[NSUpdatedObjectsKey] as? [NSManagedObject] else {
            NSLog("Change notification doesn't include updated objects.")
            return
        }
        
        let changedGuests = changedObjects.flatMap { obj in
            return obj as? Guest
        }
        
        for guest in changedGuests {
            // only detect a face in hi res photos, for guests where we don't have a face yet
            guard case let hiResPhoto? = guest.hiResPhoto, case .none = guest.hiResPhotoFaceBoundsRect else {
                return
            }
            
            DispatchQueue.main.async { [weak self, guestObjectID = guest.objectID] () -> Void in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.findFace(in: hiResPhoto, forGuestWithID: guestObjectID)
            }
        }
    }
    
    func findFace(in photo: UIImage, forGuestWithID guestObjectID: NSManagedObjectID) {
        faceDetector.findFace(photo) { [weak self] face in
            guard let strongSelf = self else { return }
            let moc = strongSelf.managedObjectContext
            moc.perform({ () -> Void in
                guard let guest = moc.object(with: guestObjectID) as? Guest else {
                    return
                }
                
                guest.hiResPhotoFaceBoundsRect = face
                do {
                    try moc.save()
                } catch {
                    NSLog("Error saving after finding a face in a guest image: %@", error as NSError)
                }
            })
        }
    }
}
