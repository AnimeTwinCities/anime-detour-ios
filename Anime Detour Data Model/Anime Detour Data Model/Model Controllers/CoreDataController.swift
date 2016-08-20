//
//  CoreDataController.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import CoreData
import UIKit

open class CoreDataController {
    fileprivate class var storeFilename: String {
        return "AnimeDetourDataModel.sqlite"
    }
    
    open class var URLForDefaultStoreFile: URL {
        return URLForStoreWithFilename(storeFilename)
    }

    /// Main managed object context, suitable only for use on the main thread.
    open let managedObjectContext: NSManagedObjectContext
    fileprivate let persistentStoreCoordinator: NSPersistentStoreCoordinator

    public init() {
        let mom = type(of: self).createManagedObjectModel()

        let psc = type(of: self).createPersistentStoreCoordinator(mom, storeFilename: CoreDataController.storeFilename)
        self.persistentStoreCoordinator = psc

        let moc = type(of: self).createManagedObjectContext(psc)
        self.managedObjectContext = moc
    }

    // MARK: - Core Data stack

    fileprivate class var applicationDocumentsDirectory: URL {
        // The directory the application uses to store the Core Data store file. This code uses the application's documents directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as URL
    }

    /**
    The managed object model for the application. 
    It is a fatal error for the application not to be able to find and load its model.
    */
    class func createManagedObjectModel() -> NSManagedObjectModel {
        let modelURL = Bundle(for: CoreDataController.self).url(forResource: "AnimeDetourDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }

    /**
    Create a persistent store coordinator for the application. This implementation creates and returns a coordinator,
    having added the store for the application to it. Returns `nil` if the creation of the store fails.
    */
    fileprivate class func createPersistentStoreCoordinator(_ managedObjectModel: NSManagedObjectModel, storeFilename: String) -> NSPersistentStoreCoordinator {
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

    fileprivate class func addPersistentStore(_ url: URL, coordinator: NSPersistentStoreCoordinator) throws {
        let options = [ NSMigratePersistentStoresAutomaticallyOption : NSNumber(value: true),
            NSInferMappingModelAutomaticallyOption : NSNumber(value: true)]
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
    }

    /// Creates a managed object context that uses the persistent store coordinator.
    fileprivate class func createManagedObjectContext(_ persistentStoreCoordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
    }
    
    fileprivate class func URLForStoreWithFilename(_ filename: String) -> URL {
        return self.applicationDocumentsDirectory.appendingPathComponent(storeFilename)
    }

    /// Create a new managed object context sharing the same store as our main context.
    /// Will be created on the calling thread.
    open func createManagedObjectContext(_ concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }

    /// Destroys and re-creates the persistent store. Not safe to use
    /// if any additional contexts have been created aside from our primary `managedObjectContext`.
    open func clearPersistentStore() {
        if let store = self.persistentStoreCoordinator.persistentStores.first {
            let url = store.url!

            do {
                try self.persistentStoreCoordinator.remove(store)
            } catch {
                let error = error as NSError
                assertionFailure("Unexpected error removing existing persistent store: \(error)")
            }
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                let error = error as NSError
                assertionFailure("Unexpected error removing existing persistent store file: \(error)")
            }
            
            do {
                try type(of: self).addPersistentStore(url, coordinator: self.persistentStoreCoordinator)
            } catch {
                let error = error as NSError
                assertionFailure("Error re-adding store to PSC: \(error)")
            }
        }
    }

    // MARK: - Core Data Saving support

    open func saveContext () {
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
