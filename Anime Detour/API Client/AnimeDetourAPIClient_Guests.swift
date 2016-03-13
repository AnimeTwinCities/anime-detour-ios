//
//  AnimeDetourAPIClient_Guests.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/15/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

import AnimeDetourDataModel
import AnimeDetourAPI
import CoreData

extension AnimeDetourAPIClient {
    func fetchGuests(dataStatusDefaultsController: DataStatusDefaultsController, managedObjectContext: NSManagedObjectContext) {
        self.guestList { [weak self] (result, error) -> () in
            guard let result = result where result.count > 0 else {
                if let error = error {
                    NSLog("Error fetching guest list from server: \(error)")
                }
                
                return
            }
            
            // Though we don't need a reference to self, copy the usual
            // behavior of skipping completion logic if `self` was deallocated.
            guard let _ = self else {
                return
            }
            
            guard let guestsJson = result as? [[String : AnyObject]] else { return }
            let context = managedObjectContext
            context.performBlock { () -> Void in
                let guestEntity = NSEntityDescription.entityForName(Guest.entityName, inManagedObjectContext: context)!
                
                for category in guestsJson {
                    guard let categoryName = category["categoryname"] as? String,
                        guests = category["guests"] as? [[String : String]] else {
                            continue
                    }
                    
                    for json: [String : String] in guests {
                        let guest = Guest(entity: guestEntity, insertIntoManagedObjectContext: context)
                        guest.update(categoryName: categoryName, jsonObject: json)
                    }
                }
                
                do {
                    try context.save()
                    dataStatusDefaultsController.guestsFetchRequired = false
                    dataStatusDefaultsController.lastGuestsClearDate = NSDate()
                    
                    dataStatusDefaultsController.synchronizeDefaults()
                } catch {
                    let error = error
                    NSLog("Error saving guests: \(error)")
                }
            }
        }
    }
}