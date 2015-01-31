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

import AnimeDetourAPI

/**
Provides UI-displayable properties corresponding to a `Guest` object.
Only safe to use on the main thread. Two instances are considered equal
if they are created to represent `Guest`s with the same `managedObjectID`s.
Other properties on two equal instances may differ.
*/
class GuestViewModel: Equatable {
    private let guestObjectID: NSManagedObjectID
    private let managedObjectContext: NSManagedObjectContext
    private let imageSession: NSURLSession

    let name: String
    let bio: String
    let category: String

    var delegate: GuestViewModelDelegate?

    private let photoPath: String
    private let hiResPhotoPath: String
    private(set) lazy var htmlBio: NSAttributedString = {
        let data = self.bio.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let string = NSAttributedString(data: data,
            options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType],
            documentAttributes: nil,
            error: nil)
        return string!
    }()

    private(set) var photo: UIImage?
    private(set) var hiResPhoto: UIImage?

    // Store our download tasks to cancel them in deinit,
    // if they are still running at that time.
    private var photoDataTask: NSURLSessionDataTask?
    private var hiResPhotoDataTask: NSURLSessionDataTask?

    /**
    Create an instance.
    
    :param: guest The guest model which this object will represent. Its `managedObjectContext` must
    be a queue-based concurrency type context. `MainQueueConcurrencyType` is recommended.
    */
    init(guest: Guest, imageSession: NSURLSession) {
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
    }

    /**
    Returns the `Guest`'s low-resolution photo, if present, and if not,
    may download the photo.
    
    :param: downloadIfNecessary If `true`, and `self.photo` is `nil`, this method will start a download of the  update the `Guest` passed into the constructor with the photo,
    save the
    */
    func photo(downloadIfNecessary: Bool) -> UIImage? {
        if let photo = self.photo {
            return photo
        }

        if !downloadIfNecessary {
            return nil
        }

        let url = NSURL(string: self.photoPath)!
        let photoTask = self.imageSession.dataTaskWithURL(url, completionHandler: { [weak self] (data: NSData?, response: NSURLResponse!, error: NSError!) -> Void in
            if let strongSelf = self {
                if let error = error {
                    strongSelf.delegate?.didFailDownloadingPhoto(strongSelf, error: error)
                    return
                }

                if let data = data {
                    if let image = UIImage(data: data) {
                        strongSelf.photo = image

                        let moc = strongSelf.managedObjectContext
                        moc.performBlockAndWait {
                            if let guest = strongSelf.managedObjectContext.objectWithID(strongSelf.guestObjectID) as? Guest {
                                guest.photo = image
                                moc.save(nil)
                            }
                        }

                        strongSelf.delegate?.didDownloadPhoto(strongSelf, photo: image, hiRes: false)
                    }
                }
            }
        })
        self.photoDataTask = photoTask
        photoTask.resume()

        return nil
    }

    func hiResPhoto(downloadIfNecessary: Bool) -> UIImage? {
        if let photo = self.hiResPhoto {
            return photo
        }

        if !downloadIfNecessary {
            return nil
        }

        let url = NSURL(string: self.hiResPhotoPath)!
        let hiResPhotoTask = self.imageSession.dataTaskWithURL(url, completionHandler: { [weak self] (data: NSData?, response: NSURLResponse!, error: NSError!) -> Void in
            if let strongSelf = self {
                if let error = error {
                    strongSelf.delegate?.didFailDownloadingPhoto(strongSelf, error: error)
                    return
                }

                if let data = data {
                    if let image = UIImage(data: data) {
                        let moc = strongSelf.managedObjectContext
                        moc.performBlockAndWait {
                            if let guest = strongSelf.managedObjectContext.objectWithID(strongSelf.guestObjectID) as? Guest {
                                guest.hiResPhoto = image
                                moc.save(nil)
                            }
                        }

                        strongSelf.delegate?.didDownloadPhoto(strongSelf, photo: image, hiRes: true)
                    }
                }
            }
        })
        self.hiResPhotoDataTask = hiResPhotoTask
        hiResPhotoTask.resume()
        
        return nil
    }

    deinit {
        self.photoDataTask?.cancel()
        self.hiResPhotoDataTask?.cancel()
    }
}

func ==(obj1: GuestViewModel, obj2: GuestViewModel) -> Bool {
    return obj1.guestObjectID.isEqual(obj2.guestObjectID)
}

protocol GuestViewModelDelegate {
    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool)
    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError)
}
