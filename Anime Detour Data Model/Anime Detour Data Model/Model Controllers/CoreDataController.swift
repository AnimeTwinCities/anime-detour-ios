//
//  CoreDataController.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import CoreData
import UIKit

public class CoreDataController {
    private class var storeFilename: String {
        return "AnimeDetourDataModel.sqlite"
    }
    
    public class var URLForDefaultStoreFile: NSURL {
        return URLForStoreWithFilename(storeFilename)
    }

    /// Main managed object context, suitable only for use on the main thread.
    public let managedObjectContext: NSManagedObjectContext
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

    public init() {
        let mom = self.dynamicType.createManagedObjectModel()

        let psc = self.dynamicType.createPersistentStoreCoordinator(mom, storeFilename: CoreDataController.storeFilename)
        self.persistentStoreCoordinator = psc

        let moc = self.dynamicType.createManagedObjectContext(psc)
        self.managedObjectContext = moc
    }

    // MARK: - Core Data stack

    private class var applicationDocumentsDirectory: NSURL {
        // The directory the application uses to store the Core Data store file. This code uses the application's documents directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }

    /**
    The managed object model for the application. 
    It is a fatal error for the application not to be able to find and load its model.
    */
    class func createManagedObjectModel() -> NSManagedObjectModel {
        let modelURL = NSBundle(forClass: CoreDataController.self).URLForResource("AnimeDetourDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }

    /**
    Create a persistent store coordinator for the application. This implementation creates and returns a coordinator,
    having added the store for the application to it. Returns `nil` if the creation of the store fails.
    */
    private class func createPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel, storeFilename: String) -> NSPersistentStoreCoordinator {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = self.URLForStoreWithFilename(storeFilename)
        do {
            try self.addPersistentStore(url, coordinator: coordinator)
        } catch {
            let error = error as NSError
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        }

        return coordinator
    }

    private class func addPersistentStore(url: NSURL, coordinator: NSPersistentStoreCoordinator) throws {
        let options = [ NSMigratePersistentStoresAutomaticallyOption : NSNumber(bool: true),
            NSInferMappingModelAutomaticallyOption : NSNumber(bool: true)]
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
    }

    /// Creates a managed object context that uses the persistent store coordinator.
    private class func createManagedObjectContext(persistentStoreCoordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }
    
    private class func URLForStoreWithFilename(filename: String) -> NSURL {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent(storeFilename)
    }

    /// Create a new managed object context sharing the same store as our main context.
    /// Will be created on the calling thread.
    public func createManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }

    /// Destroys and re-creates the persistent store. Not safe to use
    /// if any additional contexts have been created aside from our primary `managedObjectContext`.
    public func clearPersistentStore() {
        if let store = self.persistentStoreCoordinator.persistentStores.first {
            let url = store.URL!

            do {
                try self.persistentStoreCoordinator.removePersistentStore(store)
            } catch {
                let error = error as NSError
                assertionFailure("Unexpected error removing existing persistent store: \(error)")
            }
            do {
                try NSFileManager.defaultManager().removeItemAtURL(url)
            } catch {
                let error = error as NSError
                assertionFailure("Unexpected error removing existing persistent store file: \(error)")
            }
            
            do {
                try self.dynamicType.addPersistentStore(url, coordinator: self.persistentStoreCoordinator)
            } catch {
                let error = error as NSError
                assertionFailure("Error re-adding store to PSC: \(error)")
            }
        }
    }

    // MARK: - Core Data Saving support

    public func saveContext () {
        let moc = self.managedObjectContext
        guard moc.hasChanges else { return }
        do {
            try moc.save()
        } catch {
            let error = error as NSError
            
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
}
