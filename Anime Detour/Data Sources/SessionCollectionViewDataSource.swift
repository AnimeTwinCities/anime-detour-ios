//
//  SessionCollectionViewDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/12/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit
import ConScheduleKit

class SessionCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    internal var sessions: [Session] = []
    internal var cellIdentifier = "SessionCell"
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
    
    func session(indexPath: NSIndexPath) -> Session {
        return self.sessions[indexPath.row]
    }
    
    func heightForWidth(cellWidth width: CGFloat, indexPath: NSIndexPath) -> CGFloat {
        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
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
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.cellIdentifier, forIndexPath: indexPath) as SessionCollectionViewCell
        
        let session = self.session(indexPath)
        let viewModel = SessionViewModel(session: session, sessionStartTimeFormatter: self.dateFormatter, shortTimeFormatter: self.timeOnlyDateFormatter)
        cell.viewModel = viewModel
        
        return cell
    }
}