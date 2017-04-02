//
//  SessionsTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 4/1/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

class SessionsTableViewController: UITableViewController {
    @IBInspectable var reuseId: String!
    var sessions: [SessionViewModel] = []

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseId)!
        return cell
    }
}
