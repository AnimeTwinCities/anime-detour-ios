//
//  SessionBookmark.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/2/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation
import CoreData

class SessionBookmark: NSManagedObject {
    class var entityName: String { return "SessionBookmark" }

    @NSManaged var sessionID: String
}
