//
//  MapsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import QuickLook

class MapsViewController: UIViewController, QLPreviewControllerDataSource {
    private var previewController: QLPreviewController!
    private let mapFileNames = ["DoubleTree_Floor1_2015", "DoubleTree_Floor2_2015", "DoubleTree_Floor22_2015"]
    lazy private var mapPaths: [String] = {
        let mainBundle = NSBundle.mainBundle()
        let mapPaths = self.mapFileNames.map { (filename: String) -> String in
            return mainBundle.pathForResource(filename, ofType: "jpg")!
        }

        return mapPaths
    }()
    private var activeMapIndex: Int = 0 {
        didSet {
            self.previewController.reloadData()
        }
    }

    private var observingPreviewIndex = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.automaticallyAdjustsScrollViewInsets = true
        self.previewController = previewController
        
        previewController.view.backgroundColor = UIColor.clearColor()
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(previewController.view)
        let bindings: [String : AnyObject] = [
            "preview" : previewController.view,
            "top" : self.topLayoutGuide,
            "bottom" : self.bottomLayoutGuide
        ]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[preview]|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[top][preview][bottom]", options: [], metrics: nil, views: bindings)
        let previewConstraints = hConstraints + vConstraints
        self.view.addConstraints(previewConstraints)
        
        self.addChildViewController(previewController)

        previewController.currentPreviewItemIndex = 0
    }

    // MARK: - Segmented Control

    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl?) {
        self.activeMapIndex = sender?.selectedSegmentIndex ?? 0
    }

    // MARK: - Preview Controller Data Source

    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        // Assume that we only ever want to show one item, at `activeMapIndex`.
        // Change `activeMapIndex` to change the active item.
        let item = NSURL(fileURLWithPath: self.mapPaths[self.activeMapIndex], isDirectory: false)
        return item
    }
}
