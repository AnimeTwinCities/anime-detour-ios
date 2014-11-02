//
//  SessionCollectionViewDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import CoreData
import UIKit

import ConScheduleKit

class SessionCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    let imagesURLSession: NSURLSession?
    let fetchedResultsController: NSFetchedResultsController
    let userDataController: UserDataController?
    var sessionCellIdentifier = "SessionCell"
    var sectionHeaderIdentifier = "SessionSectionHeader"

    private var shortDateFormat = "MM/dd hh:mm a"
    lazy private var dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = self.shortDateFormat
        return formatter
    }()
    lazy private var timeOnlyDateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()

    /**
    Create a data source.
    
    :param: imagesURLSession The NSURLSession to use for downloading images. If `nil`, images will not be downloaded.
    :param: fetchedResultsController An FRC fetching Sessions to display in a collection view.
    :param: userDataController A controller for interacting with user models, e.g. bookmarked Sessions.
    */
    init(fetchedResultsController: NSFetchedResultsController, imagesURLSession: NSURLSession?, userDataController: UserDataController?) {
        self.imagesURLSession = imagesURLSession
        self.fetchedResultsController = fetchedResultsController
        self.userDataController = userDataController
        super.init()
    }

    /// Prepare a collection view so the data source may supply it views.
    func prepareCollectionView(collectionView: UICollectionView) {
        collectionView.registerClass(SessionCollectionViewHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: self.sectionHeaderIdentifier)
    }
    
    func session(indexPath: NSIndexPath) -> Session {
        return self.fetchedResultsController.objectAtIndexPath(indexPath) as Session
    }

    func headerText(forSection sectionNumber: Int) -> String {
        let sectionInfo = self.fetchedResultsController.sections![sectionNumber] as NSFetchedResultsSectionInfo
        let name = sectionInfo.name ?? "No header name"
        return name
    }
    
    func heightForWidth(cellWidth width: CGFloat, indexPath: NSIndexPath) -> CGFloat {
        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, imagesURLSession: nil, userDataController: nil, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        let name = viewModel.name as NSString
        let description = viewModel.sessionDescription as NSString
        let time = viewModel.dateAndTime as NSString
        
        let margins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        let interLabelPadding: CGFloat = 8
        // TODO: remove `unsafeBitCast` once NSStringDrawingOptions supports bitwise-or in Swift
        let drawingOptions: NSStringDrawingOptions = unsafeBitCast(NSStringDrawingOptions.UsesFontLeading.rawValue | NSStringDrawingOptions.UsesLineFragmentOrigin.rawValue, NSStringDrawingOptions.self)
        
        let maxNameHeight: CGFloat = 40
        let widthMinusMargins = width - (margins.left + margins.right)
        let nameHeightMaxSize = CGSize(width: widthMinusMargins, height: maxNameHeight)
        let nameFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        let nameSizingRect = name.boundingRectWithSize(nameHeightMaxSize, options: drawingOptions, attributes: [NSFontAttributeName : nameFont], context: nil)
        
        let maxDescriptionHeight: CGFloat = 80
        let descHeightMaxSize = CGSize(width: widthMinusMargins, height: maxDescriptionHeight)
        let descFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        let descSizingRect = description.boundingRectWithSize(descHeightMaxSize, options: drawingOptions, attributes: [NSFontAttributeName : descFont], context: nil)
        
        let timeHeightMaxSize = CGSize(width: widthMinusMargins, height: CGFloat.max)
        let timeFont = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        let timeSizingRect = time.boundingRectWithSize(timeHeightMaxSize, options: drawingOptions, attributes: [NSFontAttributeName : timeFont], context: nil)
        
        let totalHeight = margins.top + ceil(nameSizingRect.height) + interLabelPadding + ceil(descSizingRect.height) + interLabelPadding + ceil(timeSizingRect.height) + margins.bottom
        let integerHeight = ceil(totalHeight)
        return integerHeight
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sections = self.fetchedResultsController.sections
        let sectionInfo = sections![section] as NSFetchedResultsSectionInfo
        let count = sectionInfo.numberOfObjects
        return count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.sessionCellIdentifier, forIndexPath: indexPath) as SessionCollectionViewCell
        
        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, imagesURLSession: self.imagesURLSession, userDataController: self.userDataController, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        cell.viewModel = viewModel
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: self.sectionHeaderIdentifier, forIndexPath: indexPath) as SessionCollectionViewHeaderView
            header.title = self.headerText(forSection: indexPath.section)
            return header
        default:
            assertionFailure("Unexpected supplementary view kind: \(kind)")
        }
    }
}