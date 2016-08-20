//
//  Guest.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation
import CoreData
import UIKit

open class Guest: NSManagedObject {
    public enum Keys: String {
        case guestID
        case category
        case firstName
        case hiResPhotoData
    }

    @NSManaged open var category: String
    @NSManaged open var photoPath: String
    @NSManaged open var hiResPhotoPath: String
    @NSManaged open var photoData: Data?
    @NSManaged open var hiResPhotoData: Data?
    @NSManaged open var hiResPhotoFaceBounds: NSValue?
    @NSManaged open var guestID: String
    @NSManaged open var firstName: String
    @NSManaged open var lastName: String
    @NSManaged open var bio: String

    open var hiResPhoto: UIImage? {
        get {
            return self.hiResPhotoData.map { UIImage(data: $0) } ?? nil
        }
        set {
            self.hiResPhotoData = newValue.flatMap { UIImageJPEGRepresentation($0, 0.8) }
        }
    }

    open var photo: UIImage? {
        get {
            return self.photoData.map { UIImage(data: $0) } ?? nil
        }
        set {
            self.photoData = newValue.flatMap { UIImageJPEGRepresentation($0, 0.8) }
        }
    }

    class open var entityName: String {
        return "Guest"
    }

    override open var description: String {
        return "Guest: \(firstName) \(lastName)"
    }

    open override func awakeFromInsert() {
        super.awakeFromInsert()

        // set empty strings as default values
        self.category = ""
        self.hiResPhotoPath = ""
        self.photoPath = ""
        self.firstName = ""
        self.lastName = ""
        self.bio = ""
    }

    open var hiResPhotoFaceBoundsRect: CGRect? {
        get {
            return hiResPhotoFaceBounds?.cgRectValue
        }
        set {
            hiResPhotoFaceBounds = newValue.map { NSValue(cgRect: $0) }
        }
    }
}
