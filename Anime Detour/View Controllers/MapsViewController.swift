//
//  MapsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import QuickLook

class MapsViewController: UIViewController {
    var dataSource: QLPreviewControllerDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainBundle = NSBundle.mainBundle()
        let mapFileNames = ["DoubleTree_Floor1_2015", "DoubleTree_Floor2_2015", "DoubleTree_Floor22_2015"]
        let mapPaths = mapFileNames.map { (filename: String) -> String in
            return mainBundle.pathForResource(filename, ofType: "jpg")!
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

        previewController.currentPreviewItemIndex = 0
    }
}
