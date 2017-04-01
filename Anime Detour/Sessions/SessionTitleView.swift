//
//  SessionTitleView.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 Show a session's title and other metadata.
 */
@IBDesignable
class SessionTitleView: UIView {
    private let fullStackView = UIStackView()
    private let titleTimeLocationStackView = UIStackView()
    private let withAddStackView = UIStackView()
    
    private let timeAndLocationLabel = UILabel()
    private let titleLabel = UILabel()
    private let trackLabel = UILabel()
    
    // Use a separate button for adding and removing from our schedule,
    // since `UIButton.updateInsetsForVerticalImageAndTitle` doesn't work
    // the way we want if the button's title or image has just changed.
    private let addButton = UIButton(type: .system)
    private let removeButton = UIButton(type: .system)
    
    private var didSetupConstraints = false
    private var isInInterfaceBuilder = false
    
    override var intrinsicContentSize: CGSize {
        return fullStackView.intrinsicContentSize
    }
    
    var viewModel: SessionViewModel? {
        didSet {
            guard let _ = viewModel else {
                assertionFailure("Setting a nil view model is probably wrong.")
                return
            }
            
            updateFromViewModel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addButton.updateInsetsForVerticalImageAndTitle()
        removeButton.updateInsetsForVerticalImageAndTitle()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        isInInterfaceBuilder = true
        dev_updateAppearance()
        
        viewModel = SessionViewModel(sessionID: "dummy", title: "Sample Session", description: "Sample Description", isStarred: true, category: SessionViewModel.Category(name: "android"), room: "auditorium", start: Date(timeIntervalSince1970: 1486216800), end: nil, speakerIDs: [], tags: [])
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        guard !didSetupConstraints else {
            return
        }
        didSetupConstraints = true
        
        fullStackView.dev_constrainToSuperEdges()
        
        let trackConstraints: [NSLayoutConstraint] = [
            trackLabel.heightAnchor.constraint(equalToConstant: .dev_trackLabelHeight),
            ]
        NSLayoutConstraint.activate(trackConstraints)
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        trackLabel.font = .dev_sessionCategoryFont
        timeAndLocationLabel.font = .dev_sessionLocationFont
        titleLabel.font = .dev_sessionTitleFont
        titleTimeLocationStackView.spacing = .dev_tightMargin
        fullStackView.spacing = .dev_standardMargin
        
        let trackLayer = trackLabel.layer
        trackLayer.cornerRadius = .dev_standardMargin / 2
        trackLayer.masksToBounds = true
    }
    
    private func commonInit() {
        let addImage: UIImage
        let removeImage: UIImage
        if isInInterfaceBuilder {
            let bundle = Bundle(for: SessionTitleView.self)
            addImage = UIImage(named: "favorite-icons8", in: bundle, compatibleWith: nil)!
            removeImage = UIImage(named: "favorite-filled-icons8", in: bundle, compatibleWith: nil)!
        } else {
            addImage = #imageLiteral(resourceName: "star")
            removeImage = #imageLiteral(resourceName: "star_filled")
        }
        addButton.setImage(addImage, for: .normal)
        removeButton.setImage(removeImage, for: .normal)
        
        let addTitle = NSLocalizedString("Add", comment: "Add to schedule button on session details")
        addButton.setTitle(addTitle, for: .normal)
        
        let removeTitle = NSLocalizedString("Added", comment: "Remove from schedule button on session details")
        removeButton.setTitle(removeTitle, for: .normal)
        
        addButton.addTarget(self, action: #selector(toggleInSchedule(_:)), for: .touchUpInside)
        removeButton.addTarget(self, action: #selector(toggleInSchedule(_:)), for: .touchUpInside)
        
        removeButton.isHidden = true
        
        timeAndLocationLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        
        trackLabel.textAlignment = .center
        
        titleTimeLocationStackView.axis = .vertical
        titleTimeLocationStackView.distribution = .fillProportionally
        titleTimeLocationStackView.addArrangedSubview(titleLabel)
        titleTimeLocationStackView.addArrangedSubview(timeAndLocationLabel)
        
        withAddStackView.alignment = .center
        withAddStackView.axis = .horizontal
        withAddStackView.distribution = .equalSpacing
        withAddStackView.addArrangedSubview(titleTimeLocationStackView)
        withAddStackView.addArrangedSubview(addButton)
        withAddStackView.addArrangedSubview(removeButton)
        
        fullStackView.axis = .vertical
        fullStackView.distribution = .fill
        fullStackView.addArrangedSubview(withAddStackView)
        fullStackView.addArrangedSubview(trackLabel)
        dev_addSubview(fullStackView)
        
        dev_registerForAppearanceUpdates()
        dev_updateAppearance()
    }
    
    private func updateFromViewModel() {
        guard let viewModel = viewModel else {
            return
        }
        
        defer {
            invalidateIntrinsicContentSize()
        }
        
        if viewModel.isStarred {
            addButton.isHidden = true
            removeButton.isHidden = false
        } else {
            addButton.isHidden = false
            removeButton.isHidden = true
        }
        addButton.updateInsetsForVerticalImageAndTitle()
        removeButton.updateInsetsForVerticalImageAndTitle()
        
        // Use a `do` block to limit the scope of some variables
        do {
            let haveTime: Bool
            let haveLocation: Bool
            let timeAndLocation: String?
            let accessibilityLabel: String?
            defer {
                if let timeAndLocation = timeAndLocation {
                    timeAndLocationLabel.isHidden = false
                    timeAndLocationLabel.text = timeAndLocation
                } else {
                    timeAndLocationLabel.isHidden = true
                }
                
                timeAndLocationLabel.accessibilityLabel = accessibilityLabel
            }
            
            switch (viewModel.room, viewModel.durationString(using: .adr_startAndEndFormatter)) {
            case let (room?, duration?):
                timeAndLocation = String.init(format: NSLocalizedString("%@ · %@", comment: "Format string for a session's time and location"), duration, room)
                accessibilityLabel = NSLocalizedString("Time: \(duration). In room: \(room).", comment: "Accessible version of a session's time and location")
            case let (room?, nil):
                timeAndLocation = room
                accessibilityLabel = NSLocalizedString("In room: \(room)", comment: "Accessible version of a session's location")
            case let (nil, duration?):
                timeAndLocation = duration
                accessibilityLabel = NSLocalizedString("Time: \(duration)", comment: "Accessible version of a session's time")
            case (nil, nil):
                timeAndLocation = nil
                accessibilityLabel = nil
            }
        }
        
        titleLabel.text = viewModel.title
        
        let categoryColor = viewModel.color
        trackLabel.backgroundColor = categoryColor
        // Assume that category colors are relatively dark, so always use white text.
        trackLabel.textColor = .white
        
        var trackLabelText = viewModel.category?.name
        if let trackText = trackLabelText {
            if viewModel.is18Plus {
                trackLabelText = String(format: NSLocalizedString("%@ · 18+", comment: "18+ indicator with session track"), trackText)
            } else if viewModel.is21Plus {
                trackLabelText = String(format: NSLocalizedString("%@ · 21+", comment: "21+ indicator with session track"), trackText)
            }
        }
        trackLabel.text = trackLabelText
    }
    
    /**
     Add or remove the session for `viewModel` from the user's schedule,
     using the responder chain.
     */
    @objc private func toggleInSchedule(_ sender: Any) {
        guard let viewModel = viewModel else {
            return
        }
        
        if sender as? UIButton === addButton {
            assert(viewModel.isStarred == false)
        } else if sender as? UIButton === removeButton {
            assert(viewModel.isStarred == true)
        }
        
        if viewModel.isStarred {
            dev_removeSessionFromSchedule()
        } else {
            dev_addSessionToSchedule()
        }
    }
}

extension UIResponder {
    func dev_addSessionToSchedule() {
        next?.dev_addSessionToSchedule()
    }
    
    func dev_removeSessionFromSchedule() {
        next?.dev_removeSessionFromSchedule()
    }
}
