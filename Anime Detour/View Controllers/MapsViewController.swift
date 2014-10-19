//
//  MapsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit

import QuickLook

class MapsViewController: UIViewController {
    var dataSource: QLPreviewControllerDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainBundle = NSBundle.mainBundle()
        let mapFileNames = ["Dijkstra on numbering EWD831"]
        let mapPaths = mapFileNames.map { (filename: String) -> String in
            return mainBundle.pathForResource(filename, ofType: "pdf")!
        }
        
        let dataSource = MapsDataSource(mapFilePaths: mapPaths)
        self.dataSource = dataSource
        
        let previewController = QLPreviewController()
        previewController.dataSource = self.dataSource
        previewController.automaticallyAdjustsScrollViewInsets = true
        
        previewController.view.backgroundColor = UIColor.clearColor()
        self.view.addSubview(previewController.view)
        let bindings = ["preview" : previewController.view]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[preview]|", options: .allZeros, metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[preview]|", options: .allZeros, metrics: nil, views: bindings)
        let previewConstraints = hConstraints + vConstraints
        self.view.addConstraints(previewConstraints)
        
        self.addChildViewController(previewController)
    }
    
    override func addChildViewController(childController: UIViewController) {
        super.addChildViewController(childController)
        
        if let previewController = childController as? QLPreviewController {
        }
    }
}
