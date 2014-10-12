//
//  FirstViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/11/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

import ConScheduleKit

class FirstViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    lazy var apiClient = ScheduleAPIClient(subdomain: "ssetest2015", apiKey: "21856730f40671b94b132ca11d35cd5d")
    var dataSource = SessionTableViewDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.dataSource = self.dataSource
        
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
                
                self?.dataSource.sessions = sessions
                self?.tableView.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

class SessionTableViewDataSource: NSObject, UITableViewDataSource {
    var sessions: [Session] = []
    var cellIdentifier = "SessionCell"
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = self.sessions[indexPath.row].name
        
        return cell
    }
}
