//
//  SpeakerViewModel.swift
//  DevFest
//
//  Created by Brendon Justin on 11/24/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

struct SpeakerViewModel {
    let speakerID: String
    let name: String
    let bio: String
    
    // optionals
    let company: String?
    let imageURL: URL?
    let twitter: String?
    let website: URL?
    
    var twitterURL: URL? {
        guard let twitter = twitter else {
            return nil
        }
        
        let baseURL = URL(string: "https://twitter.com/#!/")!
        let completeURL = baseURL.appendingPathComponent(twitter)
        return completeURL
    }
}

extension UIImage {
    static let speakerPlaceholder = UIImage(named: "speaker-placeholder")!
}
