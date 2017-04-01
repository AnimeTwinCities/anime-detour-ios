//
//  SpeakerTitleView.swift
//  DevFest
//
//  Created by Brendon Justin on 11/29/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

/**
 A view for showing some basic info about a speaker, including an image, their name,
 and an organization with which they are associated.
 */
@IBDesignable
final class SpeakerTitleView: UIView {
    fileprivate let titleLabel = UILabel()
    fileprivate let subtitleLabel = UILabel()
    /**
     A container for the image view. We round the image view using its layer,
     and set a shadow on the container view's layer. We can't set a shadow on the
     image view, because then we'd have to turn off `masksToBounds`, but we need
     to mask it for the rounding to work.
     */
    fileprivate let imageContainerView = UIView()
    fileprivate let imageView = UIImageView()
    fileprivate lazy var titleSubtitleStackView: UIStackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel,])
    fileprivate lazy var horizontalStackView: UIStackView = UIStackView(arrangedSubviews: [self.imageContainerView, self.titleSubtitleStackView,])
    
    /**
     Constrain the width of the image view.
     */
    fileprivate var imageContainerViewWidthConstraint: NSLayoutConstraint?
    
    /**
     Constraints between subviews and `self`. Track these so we only add them once when
     this class is used in interface builder.
     */
    fileprivate var addedConstraints: [NSLayoutConstraint] = []
    
    /**
     The spacing in the stack view that contains the image container and the title/subtitle stack view.
     */
    fileprivate var imageTitleSpacing: CGFloat { return CGFloat.dev_standardMargin * 2 }
    
    var viewModel: SpeakerViewModel? {
        didSet {
            titleLabel.text = viewModel?.name
            subtitleLabel.text = viewModel?.company
            
            invalidateIntrinsicContentSize()
        }
    }
    
    var faceRect: CGRect? {
        didSet {
            // ignore the faceRect for now
        }
    }
    
    /**
     The speaker's photo.
     */
    var image: UIImage? {
        didSet {
            if let image = image {
                imageView.image = image
                imageContainerView.isHidden = false
            } else {
                imageContainerView.isHidden = true
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let maxSize = CGSize(width: .max, height: .max)
        let horizontalStackViewSize = horizontalStackView.systemLayoutSizeFitting(maxSize)
        
        let width = horizontalStackViewSize.width + layoutMargins.left + layoutMargins.right
        let height = horizontalStackViewSize.height + layoutMargins.top + layoutMargins.bottom
        
        return CGSize(width: width, height: height)
    }
    
    init() {
        super.init(frame: .zero)
        subviewsInit()
        
        dev_registerForAppearanceUpdates()
    }
    
    /**
     Only present for IB. Use `init()` instead.
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        // Include `init(frame:)` so we work via IBDesignable, but keep `subviewsInit` in
        // `prepareForInterfaceBuilder` since IB doesn't like some of that logic in an `init`.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        subviewsInit()
        
        // only run this once, in `init`.
        dev_registerForAppearanceUpdates()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layer = imageView.layer
        let width = imageView.frame.width
        if width > 0 {
            layer.cornerRadius = width / 2
        }
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        viewModel = SpeakerViewModel(speakerID: "dummy", name: "Speaker Name", bio: "Sample bio here.", company: "Organization, LLC", imageURL: nil, twitter: nil, website: nil)
        
        // We can't use UIImage(named:) or image literals when previewing a view in IB,
        // so manually find the image in our bundle.
        let bundleForImage = Bundle(for: SpeakerTitleView.self)
        let placeholderImage = UIImage(named: "speaker-placeholder", in: bundleForImage, compatibleWith: nil)
        image = placeholderImage
        
        subviewsInit()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        titleLabel.font = .dev_speakerNameFont
        subtitleLabel.font = .dev_speakerCompanyFont
        
        let imageLayer = imageView.layer
        imageLayer.cornerRadius = .dev_authorPhotoSideLength / 2
        imageLayer.masksToBounds = true
        
        let shadowSize = CGSize(width: .dev_authorPhotoSideLength, height: .dev_authorPhotoSideLength)
        let imageContainerLayer = imageContainerView.layer
        imageContainerLayer.shadowColor = UIColor.dev_shadowColor.cgColor
        imageContainerLayer.shadowOffset = .dev_shadowOffset
        imageContainerLayer.shadowOpacity = .dev_shadowOpacity
        imageContainerLayer.shadowRadius = .dev_shadowRadius
        imageContainerLayer.shadowPath = CGPath(roundedRect: CGRect(origin: .zero, size: shadowSize), cornerWidth: .dev_authorPhotoSideLength / 2, cornerHeight: .dev_authorPhotoSideLength / 2, transform: nil)
        
        imageContainerViewWidthConstraint?.constant = .dev_authorPhotoSideLength
        horizontalStackView.spacing = imageTitleSpacing
        
        // Assume that something influencing our size has changed if `dev_updateAppearance` is called.
        invalidateIntrinsicContentSize()
    }
}

fileprivate extension SpeakerTitleView {
    func subviewsInit() {
        backgroundColor = .clear
        titleSubtitleStackView.axis = .vertical
        horizontalStackView.alignment = .center
        
        dev_addSubview(horizontalStackView)
        
        imageContainerView.dev_addSubview(imageView)
        // don't include `imageView`'s constraints in `addedConstriants`
        imageView.dev_constrainToSuperEdges()
        
        removeConstraints(addedConstraints)
        
        imageView.contentMode = .scaleAspectFill
        let imageContainerViewWidth = imageContainerView.widthAnchor.constraint(equalToConstant: .dev_authorPhotoSideLength)
        imageContainerViewWidthConstraint = imageContainerViewWidth
        imageContainerViewWidth.priority = UILayoutPriorityRequired - 1
        let imageConstraints: [NSLayoutConstraint] = [
            // Make the image container view fixed-size and square
            imageContainerViewWidth,
            imageContainerView.heightAnchor.constraint(equalTo: imageContainerView.widthAnchor, multiplier: 1),
            ]
        
        let stackConstraints = horizontalStackView.dev_constrainToSuperMargins(shouldActivate: false)
        
        addedConstraints.append(contentsOf: imageConstraints)
        addedConstraints.append(contentsOf: stackConstraints)
        
        NSLayoutConstraint.activate(addedConstraints)
        
        dev_updateAppearance()
    }
}
