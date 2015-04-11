//
//  ConModelsController.swift
//  Anime Detour API
//
//  Created by Brendon Justin on 10/24/14.
//  Copyright (c) 2014 Anime Detour. All rights reserved.
//

import CoreData
import UIKit

public class CoreDataController {
    public class var errorDomain: String {
        get {
            return "com.animedetour.anime-detour-api"
        }
    }

    private class var storeFilename: String {
        return "ConScheduleData.sqlite"
    }

    /// Main managed object context, suitable only for use on the main thread.
    public let managedObjectContext: NSManagedObjectContext
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

    public init() {
        let mom = CoreDataController.createManagedObjectModel()

        let psc = CoreDataController.createPersistentStoreCoordinator(mom, storeFilename: CoreDataController.storeFilename)
        self.persistentStoreCoordinator = psc

        let moc = CoreDataController.createManagedObjectContext(psc)
        self.managedObjectContext = moc
    }

    // MARK: - Core Data stack

    private class var applicationDocumentsDirectory: NSURL {
        // The directory the application uses to store the Core Data store file. This code uses the application's documents directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }

    /**
    The managed object model for the application. 
    It is a fatal error for the application not to be able to find and load its model.
    */
    class func createManagedObjectModel() -> NSManagedObjectModel {
        let modelURL = NSBundle(forClass: CoreDataController.self).URLForResource("AnimeDetourAPI", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }

    /**
    Create a persistent store coordinator for the application. This implementation creates and returns a coordinator,
    having added the store for the application to it. Returns `nil` if the creation of the store fails.
    */
    private class func createPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel, storeFilename: String) -> NSPersistentStoreCoordinator {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(storeFilename)
        let failureReason = "There was an error creating or loading the application's saved data."
        if let error = self.addPersistentStore(url, coordinator: coordinator) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the store for the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: self.errorDomain, code: 9999, userInfo: dict as [NSObject : AnyObject])
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }

    private class func addPersistentStore(url: NSURL, coordinator: NSPersistentStoreCoordinator) -> NSError? {
        let options = [ NSMigratePersistentStoresAutomaticallyOption : NSNumber(bool: true),
            NSInferMappingModelAutomaticallyOption : NSNumber(bool: true)]
        var error: NSError? = nil
        if coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error) == nil {
            return error
        }

        return nil
    }

    /// Creates a managed object context that uses the persistent store coordinator.
    private class func createManagedObjectContext(persistentStoreCoordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        return managedObjectContext
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
        if let store = self.persistentStoreCoordinator.persistentStores.first as? NSPersistentStore {
            let url = store.URL!

            var err: NSError?
            self.persistentStoreCoordinator.removePersistentStore(store, error: &err)
            NSFileManager.defaultManager().removeItemAtURL(url, error: &err)
            
            if let error = CoreDataController.addPersistentStore(url, coordinator: self.persistentStoreCoordinator) {
                NSLog("Error re-adding store to PSC: %@", error)
            }
        }
    }

    // MARK: - Core Data Saving support

    public func saveContext () {
        let moc = self.managedObjectContext
        var error: NSError? = nil
        if moc.hasChanges && !moc.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }
}
