//
//  ConModelsController_Singleton.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import Foundation

import AnimeDetourDataModel

extension CoreDataController {
    static var sharedInstance: CoreDataController = { () -> CoreDataController in
        // Copy our seed data into place before creating the singleton
        if let seedDataURL = Bundle.main.url(forResource: "AnimeDetourDataModel", withExtension: "sqlite") {
            let fileManager = FileManager.default
            
            let destination = CoreDataController.URLForDefaultStoreFile
            if !fileManager.fileExists(atPath: destination.path) {
                do {
                    try fileManager.copyItem(at: seedDataURL, to: destination)
                    let dataStatusDefaultsController = DataStatusDefaultsController()
                    dataStatusDefaultsController.guestsFetchRequired = false
                    dataStatusDefaultsController.sessionsFetchRequired = false
                } catch {
                    NSLog("Error copying seed data: %@", error as NSError)
                }
            }
        }
        return CoreDataController()
    }()
}
