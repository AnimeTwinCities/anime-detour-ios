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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let apiClient = ScheduleAPIClient(subdomain: "ssetest2015", apiKey: "21856730f40671b94b132ca11d35cd5d")
        apiClient.sessionList(since: nil, deletedSessions: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

