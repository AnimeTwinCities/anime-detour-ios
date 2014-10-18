//
//  SessionView.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class SessionView: UIView {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!
    
    /// Value for the image view height constraint, if an image is available.
    @IBInspectable var imageHeight: CGFloat = 180

    private var imageTask: NSURLSessionDataTask?
    private var image: UIImage? {
        didSet {
            self.imageView.image = self.image
        }
    }
    
    internal var viewModel: SessionViewModel? {
        didSet {
            self.nameLabel.text = viewModel?.name
            self.timeLabel.text = viewModel?.dateAndTime
            self.descriptionLabel.text = viewModel?.sessionDescription
            
            self.imageTask?.cancel()
            self.imageTask = nil
            
            if let imageURL = viewModel?.imageURL {
                let imageTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL, completionHandler: { [weak self] (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self?.imageTask = nil
                        self?.image = UIImage(data: data)
                    });
                })
                self.imageTask = imageTask
                imageTask.resume()
                
                self.imageViewHeightConstraint.constant = self.imageHeight
            } else {
                self.imageViewHeightConstraint.constant = 0
            }
        }
    }
}