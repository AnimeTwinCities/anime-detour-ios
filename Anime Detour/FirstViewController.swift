//
//  FirstViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

import ConScheduleKit

class FirstViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    lazy var apiClient = ScheduleAPIClient(subdomain: "ssetest2015", apiKey: "21856730f40671b94b132ca11d35cd5d")
    /**
     Collection view data source that we call through to from our data
     source methods.
     */
    private var dataSource = SessionTableViewDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
                    session.update(jsonObject: json)
                    return session
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self?.dataSource.sessions = sessions
                    self?.collectionView?.reloadData()
                })
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dataSource.numberOfSectionsInCollectionView(collectionView)
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return self.dataSource.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let frame = collectionView.frame
        
        let width = frame.width;
        var cellWidth: CGFloat
        let minCellWidth: CGFloat = 300
        var maxCellWidth = CGFloat(2.0 / 3) * minCellWidth
        if (width > maxCellWidth) {
            cellWidth = width / floor(width / minCellWidth)
        } else {
            cellWidth = width;
        }
        
        return CGSize(width: cellWidth, height: 120)
    }
}

class SessionTableViewDataSource: NSObject, UICollectionViewDataSource {
    var sessions: [Session] = []
    var cellIdentifier = "SessionCell"
    private var shortDateFormat = "MM/dd hh:mm a"
    lazy var dateFormatter: NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateFormat = self.shortDateFormat
        return formatter
    }()
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.cellIdentifier, forIndexPath: indexPath) as SessionCollectionViewCell
        let session = self.sessions[indexPath.row]
        cell.nameLabel.text = session.name
        cell.descriptionLabel.text = session.description
        
        let startDateString = self.dateFormatter.stringFromDate(session.start)
        let durationInSeconds = session.end.timeIntervalSinceDate(session.start)
        let durationInMinutes = UInt(durationInSeconds / 60)
        let durationString = "\(durationInMinutes) min."
        cell.timeLabel.text = "\(startDateString) - \(durationString)"
        
        return cell
    }
}

class SessionCollectionViewCell: UICollectionViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var timeLabel: UILabel!
    
    @IBOutlet var locationLabel: UILabel!
}
