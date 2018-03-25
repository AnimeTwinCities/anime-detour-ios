//
//  SpeakerDetailViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 1/15/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit
import SafariServices

/**
 Shows all of a speaker's information, that we have.
 */
class SpeakerDetailViewController: UIViewController, StretchingImageHeaderContainer, UIScrollViewDelegate {
    /**
     The scroll view that contains our stack view.
     */
    @IBOutlet var scrollView: UIScrollView!
    
    /**
     The stack view that contains all of our content subviews, except for imageHeaderView.
     */
    @IBOutlet var stackView: UIStackView!
    
    /**
     The stack view that contains all of our content subviews, except for imageHeaderView.
     */
    @IBOutlet var nonImageStackView: UIStackView!
    
    /**
     Contains the speaker's name and company.
     */
    @IBOutlet var nameAndCompanyStackView: UIStackView!
    @IBOutlet var imageHeaderView: ImageHeaderView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var companyLabel: UILabel!
    @IBOutlet var bioTextView: UITextView!
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var websiteButton: UIButton!
    
    var imageRepository: ImageRepository?
    
    var photoAspect: CGFloat = 2
    
    var viewModel: SpeakerViewModel? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            updateFromViewModel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker
        let dict = GAIDictionaryBuilder.createEventDictionary(.guest, action: .viewDetails, label: viewModel?.name, value: nil)
        analytics?.send(dict)
        
        imageHeaderView.image = .speakerPlaceholder
        
        nonImageStackView.isLayoutMarginsRelativeArrangement = true
        
        // Always allow vertical bouncing, so people can see more of the speaker's photo.
        scrollView.alwaysBounceVertical = true
        
        bioTextView.textContainer.lineFragmentPadding = 0
        bioTextView.textContainerInset = .zero
        
        updateFromViewModel()
        updateHeaderSize()
        
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        stackView.spacing = .dev_contentInsideVerticalMargin
        
        // Set layout margins on this stack view so our bio text view is inset from the sides
        // of our view, and the bottom-most view in the stack view isn't right up against
        // the bottom of our view.
        nonImageStackView.layoutMargins = UIEdgeInsetsMake(0, .dev_contentHorizontalMargin, .dev_contentOutsideVerticalMargin, .dev_contentHorizontalMargin)
        nonImageStackView.spacing = .dev_contentInsideVerticalMargin

        nameAndCompanyStackView.spacing = .dev_tightMargin
        
        nameLabel.font = .dev_speakerNameFont
        companyLabel.font = .dev_speakerCompanyFont
        bioTextView.font = .dev_contentFont
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderImageTopConstraint(scrollView)
    }
    
    @IBAction func showTwitterProfile(_ sender: Any) {
        guard let twitter = viewModel?.twitter else {
            assertionFailure("Twitter button should be hidden if a speaker doesn't have a Twitter handle set.")
            return
        }
        
        let twitterURL = URL(string: "https://twitter.com/")!
        guard let url = URL(string: twitter, relativeTo: twitterURL) else {
            assertionFailure("Unexpectedly unable to construct a Twitter URL for a speaker with provided Twitter handle: \(twitter)")
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        showDetailViewController(safariVC, sender: sender)
    }
    
    @IBAction func showWebsite(_ sender: Any) {
        guard let website = viewModel?.website else {
            assertionFailure("Website button should be hidden if a speaker doesn't have a website set.")
            return
        }
        
        let safariVC = SFSafariViewController(url: website)
        showDetailViewController(safariVC, sender: sender)
    }
}

private extension SpeakerDetailViewController {
    func updateFromViewModel() {
        // Assume that all speakers have a name and a bio
        nameLabel.text = viewModel?.name
        bioTextView.text = viewModel?.bio
        
        // Speakers may not have a company, twitter, or website
        if let company = viewModel?.company {
            companyLabel.isHidden = false
            companyLabel.text = company
        } else {
            companyLabel.isHidden = true
        }
        
        if let twitter = viewModel?.twitter, !twitter.isEmpty {
            twitterButton.isHidden = false
            twitterButton.setTitle("@\(twitter)", for: .normal)
        } else {
            twitterButton.isHidden = true
        }
        
        if let website = viewModel?.website, !website.absoluteString.isEmpty {
            websiteButton.isHidden = false
            websiteButton.setTitle(website.absoluteString, for: .normal)
        } else {
            websiteButton.isHidden = true
        }
        
        updateImage()
    }
    
    func updateImage() {
        guard let imageRepository = imageRepository, let imageURL = viewModel?.imageURL else {
            imageHeaderView.image = .speakerPlaceholder
            return
        }
        
        let (image, faceRect, _) = imageRepository.image(at: imageURL) { [weak self] (maybeImage, maybeFaceRect) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.imageHeaderView.faceRect = maybeFaceRect
                strongSelf.imageHeaderView.image = maybeImage ?? .speakerPlaceholder
                strongSelf.updateHeaderSize()
            }
        }
        
        imageHeaderView.faceRect = faceRect
        imageHeaderView.image = image ?? .speakerPlaceholder
        updateHeaderSize()
    }
}
