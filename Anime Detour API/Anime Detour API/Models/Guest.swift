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

public class Guest: NSManagedObject {

    @NSManaged public var category: String
    @NSManaged public var photoPath: String
    @NSManaged public var hiResPhotoPath: String
    @NSManaged public var photoData: NSData?
    @NSManaged public var hiResPhotoData: NSData?
    @NSManaged public var guestID: String
    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var bio: String

    public var hiResPhoto: UIImage? {
        get {
            return self.hiResPhotoData.map { UIImage(data: $0) } ?? nil
        }
        set {
            self.hiResPhotoData = newValue.map { UIImageJPEGRepresentation($0, 0.8) }
        }
    }

    public var photo: UIImage? {
        get {
            return self.photoData.map { UIImage(data: $0) } ?? nil
        }
        set {
            self.photoData = newValue.map { UIImageJPEGRepresentation($0, 0.8) }
        }
    }

    class public var entityName: String {
        return "Guest"
    }

    override public var description: String {
        return "Guest: \(firstName) \(lastName)"
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        // set empty strings as default values
        self.category = ""
        self.hiResPhotoPath = ""
        self.photoPath = ""
        self.firstName = ""
        self.lastName = ""
        self.bio = ""
    }

}
