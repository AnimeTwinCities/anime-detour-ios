//
//  SessionDetailViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit
import SafariServices

/**
 Display the full details for a session.
 */
class SessionDetailViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!
    
    // Our main stack view, with all of our content.
    @IBOutlet var stackView: UIStackView!
    
    // The view with the session title, time, etc
    @IBOutlet var sessionTitleView: SessionTitleView!
    
    // The text view with the session's description.
    @IBOutlet var descriptionTextView: UITextView!
    
    // A view behind the speakers list, to give it a different colored background.
    @IBOutlet var speakersSectionBackgroundView: UIView!
    
    // The title label in the speakers section.
    @IBOutlet var speakersSectionLabel: UILabel!
    
    // Contains the actual list of speaker views
    @IBOutlet var speakersStackView: UIStackView!
    
    // Rate the session.
    @IBOutlet var rateButton: UIButton!
    
    // A view that can be hidden to hide the rate button in our `stackView`.
    @IBOutlet var rateButtonContainer: UIView!
    
    weak var delegate: SessionDetailViewControllerDelegate?
    
    /// Most of the session details. The `speakerIDs` are not used.
    var viewModel: SessionViewModel? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            updateFromViewModel()
        }
    }
    
    /// The speakers to display with the session details.
    /// Used instead of `viewModel.speakerIDs`.
    var speakers: [SpeakerViewModel]? {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            updateFromViewModel()
        }
    }
    
    var imageRepository: ImageRepository?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.preservesSuperviewLayoutMargins = true
        
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.preservesSuperviewLayoutMargins = true
        
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        
        // The speakers section label is initially in our view hierarchy thanks to the storyboard.
        // We don't want to show it by default, so remove it now.
        speakersSectionLabel.removeFromSuperview()
        
        let rateTitle = NSLocalizedString("Rate Session", comment: "Rating button on session details")
        rateButton.setTitle(rateTitle, for: .normal)

        speakersSectionLabel.text = NSLocalizedString("SPEAKERS", comment: "Speakers section delineator in the session detail view")
        
        speakersStackView.isLayoutMarginsRelativeArrangement = true
        
        rateButtonContainer.isHidden = true
        
        dev_updateAppearance()
        dev_registerForAppearanceUpdates()
        
        updateFromViewModel()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        // Setting top and bottom margins on the view doesn't seem to do anything, so set those
        // on our `stackView` instead.
        view.layoutMargins = UIEdgeInsetsMake(0, .dev_contentHorizontalMargin, 0, .dev_contentHorizontalMargin)
        
        stackView.layoutMargins = UIEdgeInsetsMake(.dev_contentOutsideVerticalMargin, 0, .dev_contentOutsideVerticalMargin, 0)
        stackView.spacing = .dev_contentHorizontalMargin
        descriptionTextView.font = .dev_contentFont
        speakersSectionBackgroundView.backgroundColor = .dev_sessionSpeakersBackgroundColor
        speakersSectionLabel.font = .dev_sessionSpeakersTitleFont
        speakersStackView.layoutMargins = UIEdgeInsetsMake(.dev_contentInsideVerticalMargin, 0, .dev_contentInsideVerticalMargin, 0)
    }
    
    override func dev_addSessionToSchedule() {
        guard let viewModel = viewModel else {
            return
        }
        delegate?.addSessionToSchedule(for: viewModel, sender: self)
    }
    
    override func dev_removeSessionFromSchedule() {
        guard let viewModel = viewModel else {
            return
        }
        delegate?.removeSessionFromSchedule(for: viewModel, sender: self)
    }
    
    @IBAction func rate(_ sender: Any) {
        guard let id = viewModel?.sessionID else {
            return
        }
        
        let urlString = "https://devfest.mn/schedule/\(id)/feedback"
        guard let url = URL(string: urlString) else {
            NSLog("Couldn't make URL for rating session with ID: \(id)")
            return
        }
        
        let safari = SFSafariViewController(url: url)
        showDetailViewController(safari, sender: sender)
    }
    
    private func updateFromViewModel() {
        guard let viewModel = viewModel else {
            NSLog("Tried to update displayed information from view model, but no view model set.")
            return
        }
        
        sessionTitleView.viewModel = viewModel
        
        if let description = viewModel.description, !description.isEmpty {
            descriptionTextView.isHidden = false
            descriptionTextView.text = description
        } else {
            descriptionTextView.isHidden = true
        }
        
        updateSpeakersFromViewModel()
    }
    
    func updateSpeakersFromViewModel() {
        let speakerSubviews = speakersStackView.arrangedSubviews
        for speakerView in speakerSubviews {
            speakersStackView.removeArrangedSubview(speakerView)
            speakerView.removeFromSuperview()
        }
        
        guard let speakers = self.speakers, !speakers.isEmpty else {
            return
        }
        
        speakersStackView.addArrangedSubview(speakersSectionLabel)
        
        for speakerViewModel in speakers {
            let speakerView = SpeakerTitleView()
            speakerView.viewModel = speakerViewModel
            speakersStackView.addArrangedSubview(speakerView)
            
            if let url = speakerViewModel.imageURL, let imageRepository = imageRepository {
                let (image, faceRect, _) = imageRepository.image(at: url, completion: { [weak speakerView] (maybeImage, maybeFaceRect) in
                    DispatchQueue.main.async {
                        speakerView?.faceRect = maybeFaceRect
                        speakerView?.image = maybeImage ?? .speakerPlaceholder
                    }
                })
                speakerView.faceRect = faceRect
                speakerView.image = image ?? .speakerPlaceholder
            }
        }
    }

}

protocol SessionDetailViewControllerDelegate: class {
    func addSessionToSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController)
    func removeSessionFromSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController)
}
