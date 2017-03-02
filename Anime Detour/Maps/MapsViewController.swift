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
    fileprivate var previewController: QLPreviewController!
    fileprivate let mapFileNames = ["AnimeDetour2016-MapsOnly_1", "AnimeDetour2016-MapsOnly_2", "AnimeDetour2016-MapsOnly_3"]
    lazy fileprivate var mapPaths: [String] = {
        let mainBundle = Bundle.main
        let mapPaths = self.mapFileNames.map { (filename: String) -> String in
            return mainBundle.path(forResource: filename, ofType: "pdf")!
        }

        return mapPaths
    }()
    fileprivate var activeMapIndex: Int = 0 {
        didSet {
            previewController.reloadData()
        }
    }

    fileprivate var observingPreviewIndex = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.automaticallyAdjustsScrollViewInsets = true
        self.previewController = previewController
        
        previewController.view.backgroundColor = UIColor.clear
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewController.view)
        let bindings: [String : AnyObject] = [
            "preview" : previewController.view,
            "top" : topLayoutGuide,
            "bottom" : bottomLayoutGuide
        ]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[preview]|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[top][preview][bottom]", options: [], metrics: nil, views: bindings)
        let previewConstraints = hConstraints + vConstraints
        view.addConstraints(previewConstraints)
        
        addChildViewController(previewController)

        previewController.currentPreviewItemIndex = 0
    }

    // MARK: - Segmented Control

    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl?) {
        activeMapIndex = sender?.selectedSegmentIndex ?? 0
    }

    // MARK: - Preview Controller Data Source

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // Assume that we only ever want to show one item, at `activeMapIndex`.
        // Change `activeMapIndex` to change the active item.
        let item = URL(fileURLWithPath: mapPaths[activeMapIndex], isDirectory: false)
        // `URL` doesn't conform to `QLPreviewItem`, but `NSURL` does.
        return item as NSURL
    }
}
