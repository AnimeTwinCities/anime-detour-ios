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
    private let managedObjectContext: NSManagedObjectContext
    private let imageSession: NSURLSession

    let name: String
    let bio: String
    let category: String
    let hiResFaceBounds: CGRect?

    var delegate: GuestViewModelDelegate?

    private let photoPath: String
    private let hiResPhotoPath: String
    private(set) lazy var htmlBio: NSAttributedString = {
        let data = self.bio.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
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

    private(set) var photo: UIImage?
    private(set) var hiResPhoto: UIImage?
    var photoFaceLocation: CGRect?

    // Store our download tasks to cancel them in deinit,
    // if they are still running at that time.
    private var photoDataTask: NSURLSessionDataTask?
    private var hiResPhotoDataTask: NSURLSessionDataTask?

    /**
    Create an instance.
    
    - parameter guest: The guest model which this object will represent. Its `managedObjectContext` must
    be a queue-based concurrency type context. `MainQueueConcurrencyType` is recommended.
    */
    init(guest: Guest, imageSession: NSURLSession) {
        self.guest = guest
        self.guestObjectID = guest.objectID
        self.managedObjectContext = guest.managedObjectContext!
        self.imageSession = imageSession

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
    func photo(downloadIfNecessary: Bool) -> UIImage? {
        if let photo = self.photo {
            return photo
        }

        guard downloadIfNecessary else {
            return nil
        }

        let url = NSURL(string: self.photoPath)!
        let photoTask = self.imageSession.dataTaskWithURL(url, completionHandler: { [weak self] (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                strongSelf.delegate?.didFailDownloadingPhoto(strongSelf, error: error)
                return
            }
            
            guard let image = data.flatMap(UIImage.init) else {
                return
            }
            
            strongSelf.photo = image
            
            let moc = strongSelf.managedObjectContext
            moc.performBlockAndWait {
                guard let guest = moc.objectWithID(strongSelf.guestObjectID) as? Guest else {
                    NSLog("Couldn't find our guest object after downloading their photo. Maybe it was deleted?")
                    return
                }
                
                guest.photo = image
                do {
                    try moc.save()
                } catch {
                    let error = error as NSError
                    NSLog("Error saving after downloading regular resolution image: \(error)")
                }
            }
            
            strongSelf.delegate?.didDownloadPhoto(strongSelf, photo: image, hiRes: false)
        })
        self.photoDataTask = photoTask
        photoTask.resume()

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
    func hiResPhoto(downloadIfNecessary: Bool, lowResPhotoPlaceholder: Bool) -> UIImage? {
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
        
        guard let url = NSURL(string: self.hiResPhotoPath) else {
            return returnMethod()
        }
        
        let hiResPhotoTask = self.imageSession.dataTaskWithURL(url, completionHandler: { [weak self] (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                strongSelf.delegate?.didFailDownloadingPhoto(strongSelf, error: error)
                return
            }
            
            guard let image = data.flatMap({ UIImage(data: $0) }) else {
                return
            }
            
            let moc = strongSelf.managedObjectContext
            moc.performBlockAndWait {
                guard let guest = moc.objectWithID(strongSelf.guestObjectID) as? Guest else {
                    return
                }
                
                guest.hiResPhoto = image
                do {
                    try moc.save()
                } catch {
                    let error = error as NSError
                    NSLog("Error saving after downloading high resolution image: \(error)")
                }
            }
            
            strongSelf.delegate?.didDownloadPhoto(strongSelf, photo: image, hiRes: true)
            })
        self.hiResPhotoDataTask = hiResPhotoTask
        hiResPhotoTask.resume()
        
        return returnMethod()
    }
    
    deinit {
        self.photoDataTask?.cancel()
        self.hiResPhotoDataTask?.cancel()
    }
}

func ==(obj1: GuestViewModel, obj2: GuestViewModel) -> Bool {
    return obj1.guest.objectID.isEqual(obj2.guest.objectID)
}

protocol GuestViewModelDelegate {
    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool)
    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError)
}
