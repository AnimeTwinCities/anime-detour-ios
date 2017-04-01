//
//  SingleMapViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 4/1/17.
//  Copyright © 2017 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit

import QuickLook

class SingleMapViewController: UIViewController, QLPreviewControllerDataSource {
    fileprivate var previewController: QLPreviewController!
    let mapFilePath: String
    
    init() {
        mapFilePath = Bundle.main.path(forResource: "AnimeDetour2017DealersMap", ofType: "pdf")!
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        mapFilePath = Bundle.main.path(forResource: "AnimeDetour2017DealersMap", ofType: "pdf")!
        super.init(coder: aDecoder)
    }
    
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
    
    // MARK: - Preview Controller Data Source
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let item = URL(fileURLWithPath: mapFilePath, isDirectory: false)
        // `URL` doesn't conform to `QLPreviewItem`, but `NSURL` does.
        return item as NSURL
    }
}
