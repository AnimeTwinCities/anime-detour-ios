//
//  MapsDataSource.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Naga Softworks, LLC. All rights reserved.
//

import UIKit
import QuickLook

class MapsDataSource: NSObject, QLPreviewControllerDataSource {
    let mapPaths: [String]
    
    init(mapFilePaths mapPaths: [String]) {
        self.mapPaths = mapPaths
        super.init()
    }
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
        return self.mapPaths.count
    }
    
    func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        let item = NSURL(fileURLWithPath: self.mapPaths[index])!
        return item
    }
}