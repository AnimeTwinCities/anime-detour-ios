//
//  GuestViewModel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import AnimeDetourDataModel

/**
Provides UI-displayable properties corresponding to a `Guest` object.
Only safe to use on the main thread. Two instances are considered equal
if they are created to represent `Guest`s with the same `managedObjectID`s.
Other properties on two equal instances may differ.
*/
class GuestViewModel: Equatable {
    let guest: Guest
    let guestObjectID: NSManagedObjectID
    fileprivate let managedObjectContext: NSManagedObjectContext
    fileprivate let photoDownloader: PhotoDownloader

    let name: String
    let bio: String
    let category: String
    let hiResFaceBounds: CGRect?

    fileprivate let photoPath: String
    fileprivate let hiResPhotoPath: String
    fileprivate(set) lazy var htmlBio: NSAttributedString = {
        let data = self.bio.data(using: String.Encoding.utf8, allowLossyConversion: true)!
        let string: NSAttributedString?
        do {
            string = try NSAttributedString(data: data,
                        options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType],
                        documentAttributes: nil)
        } catch _ {
            string = nil
        }
        return string!
    }()

    fileprivate(set) var photo: UIImage?
    fileprivate(set) var hiResPhoto: UIImage?
    var photoFaceLocation: CGRect?

    /**
    Create an instance.
    
    - parameter guest: The guest model which this object will represent. Its `managedObjectContext` must
    be a queue-based concurrency type context. `MainQueueConcurrencyType` is recommended.
    */
    init(guest: Guest, photoDownloader: PhotoDownloader) {
        self.guest = guest
        self.guestObjectID = guest.objectID
        self.managedObjectContext = guest.managedObjectContext!
        self.photoDownloader = photoDownloader

        self.name = "\(guest.firstName) \(guest.lastName)"
        self.bio = guest.bio
        self.category = guest.category
        self.photo = guest.photo
        self.hiResPhoto = guest.hiResPhoto
        self.photoPath = guest.photoPath
        self.hiResPhotoPath = guest.hiResPhotoPath
        self.hiResFaceBounds = guest.hiResPhotoFaceBoundsRect
        self.photoFaceLocation = guest.hiResPhotoFaceBoundsRect
    }

    /**
     Returns the `Guest`'s low-resolution photo, if present, and if not,
     may download the photo.
     
     - parameter downloadIfNecessary: If `true`, and `self.photo` is `nil`, this method will start a download of the
     guest's high resolution photo, update the `Guest` object passed into the constructor with the photo,
     then save guest object.
     */
    func photo(_ downloadIfNecessary: Bool) -> UIImage? {
        if let photo = self.photo {
            return photo
        }

        guard downloadIfNecessary else {
            return nil
        }

        let url = URL(string: self.photoPath)!
        photoDownloader.downloadPhoto(at: url) { [weak self, guestObjectID, moc = managedObjectContext] result in
            guard case let .success(photo) = result else {
                return
            }
            
            self?.photo = photo
            
            moc.perform {
                guard let guest = moc.object(with: guestObjectID) as? Guest else {
                    NSLog("Couldn't find our guest object after downloading their photo. Maybe it was deleted?")
                    return
                }
                
                guest.photo = photo
                do {
                    try moc.save()
                } catch {
                    let error = error as NSError
                    NSLog("Error saving after downloading regular resolution image: \(error)")
                }
            }
        }

        return nil
    }

    /**
     Returns the `Guest`'s high-resolution photo, if present, and if not,
     may download the photo.
     
     - parameter downloadIfNecessary: If `true`, and `self.photo` is `nil`, this method will start a download of the
     guest's high resolution photo, update the `Guest` object passed into the constructor with the photo,
     then save guest object.
     - parameter lowResPhotoPlaceholder: If `true` and we have a low res image for the guest,
     that low res photo will be returned and the high res photo will not be downloaded.
     */
    func hiResPhoto(_ downloadIfNecessary: Bool, lowResPhotoPlaceholder: Bool) -> UIImage? {
        if let photo = self.hiResPhoto {
            return photo
        }

        let returnMethod = { () -> UIImage? in
            if lowResPhotoPlaceholder, let photo = self.photo {
                return photo
            } else {
                return nil
            }
        }

        guard downloadIfNecessary else {
            return returnMethod()
        }
        
        guard let url = URL(string: self.hiResPhotoPath) else {
            return returnMethod()
        }
        
        photoDownloader.downloadPhoto(at: url) { [weak self, guestObjectID, moc = managedObjectContext] result in
            guard case let .success(photo) = result else {
                return
            }
            
            self?.hiResPhoto = photo
            
            moc.perform {
                guard let guest = moc.object(with: guestObjectID) as? Guest else {
                    return
                }
                
                guest.hiResPhoto = photo
                do {
                    try moc.save()
                } catch {
                    let error = error as NSError
                    NSLog("Error saving after downloading high resolution image: \(error)")
                }
            }
        }
        
        return returnMethod()
    }
}

func ==(obj1: GuestViewModel, obj2: GuestViewModel) -> Bool {
    return obj1.guest.objectID.isEqual(obj2.guest.objectID)
}
