//
//  SessionsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/18/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import Foundation
import UIKit

import ConScheduleKit

class SessionsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    lazy var apiClient = ScheduleAPIClient.sharedInstance
    private var imagesURLSession = NSURLSession.sharedSession()
    
    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    private var dataSource: SessionCollectionViewDataSource!
    private var selectedSession: Session?
    
    private let sessionDetailSegueIdentifier = "SessionDetailSegueIdentifier"
    
    // Gesture recognizers
    @IBOutlet var horizontalScrollRecognizer: UIGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Sessions"
        
        if let layout = (self.collectionView.collectionViewLayout as? FilmstripsFlowLayout) {
            layout.itemSize = CGSize(width: 300, height: 120)
        }
        
        self.dataSource = SessionCollectionViewDataSource(imagesURLSession: self.imagesURLSession)
        self.apiClient.sessionList(since: nil, deletedSessions: false, completionHandler: { [weak self] (result: AnyObject?, error: NSError?) -> () in
            if result == nil {
                if let error = error {
                    // empty
                }
                
                return
            }
            
            if let jsonSessions = result as? [[String : String]] {
                let sessions = jsonSessions.map { (json: [String : String]) -> Session in
                    let session = Session()
                    session.update(jsonObject: json, jsonDateFormatter: self!.apiClient.dateFormatter)
                    return session
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self?.dataSource.sessions = sessions
                    self?.collectionView.reloadData()
                })
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        self.navigationController?.hidesBarsOnSwipe = true
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: Collection View Data Source
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dataSource.numberOfSectionsInCollectionView(collectionView)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return self.dataSource.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedSession = self.dataSource.session(indexPath)
        
        self.performSegueWithIdentifier(self.sessionDetailSegueIdentifier, sender: self)
    }

    // MARK: Gesture Recognizer Delegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer == self.horizontalScrollRecognizer {
            let collectionView = self.collectionView
            let location = touch.locationInView(collectionView)

            // Check if the touch is in a collection view cell. Return true if so.
            let subview = collectionView.hitTest(location, withEvent: nil)
            var inCell = false
            var currentView = subview
            while let superview = currentView?.superview {
                if superview == collectionView {
                    break
                }
                if superview is UICollectionViewCell {
                    inCell = true
                    break
                }

                currentView = superview
            }
            
            return inCell
        }
        
        return true
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let detailVC = segue.destinationViewController as? SessionViewController {
            detailVC.session = self.selectedSession!
        }
    }
}