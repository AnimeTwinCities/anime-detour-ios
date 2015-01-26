//
//  GuestViewModel.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation
import UIKit

import AnimeDetourAPI

class GuestViewModel {
    let name: String
    let bio: String
    let htmlBio: NSAttributedString

    /// A photo for the guest. If the hiResPhoto is not yet available,
    /// the smallPhoto will be used instead. If neither is available, will be `nil`.
    var photo: UIImage?
    var smallPhoto: UIImage?
    var hiResPhoto: UIImage?

    init(guest: Guest) {
        self.name = "\(guest.firstName) \(guest.lastName)"
        self.bio = guest.bio
        self.htmlBio = NSAttributedString(data: self.bio.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!,
            options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType],
            documentAttributes: nil,
            error: nil)!
    }
}