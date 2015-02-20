//
//  UserDataController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/2/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import CoreData
import UIKit

import AnimeDetourAPI

class UserDataController {
    class var errorDomain: String {
        return "com.animedetour.mobile"
    }

    /// Main managed object context, suitable only for use on the main thread.
    let managedObjectContext: NSManagedObjectContext
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator

    init() {
        let mom = UserDataController.createManagedObjectModel()

        let psc = UserDataController.createPersistentStoreCoordinator(mom, storeFilename: "UserData.sqlite")
        self.persistentStoreCoordinator = psc

        let moc = UserDataController.createManagedObjectContext(psc)
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
        let modelURL = NSBundle(forClass: UserDataController.self).URLForResource("UserData", withExtension: "momd")!
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
        var error: NSError? = nil
        let failureReason = "There was an error creating or loading the application's saved data."
        if let error = self.addPersistentStore(url, coordinator: coordinator) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the store for the application's saved user data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            let wrappedError = NSError(domain: self.errorDomain, code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }

    private class func addPersistentStore(url: NSURL, coordinator: NSPersistentStoreCoordinator) -> NSError? {
        var error: NSError? = nil
        if coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
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
    func createManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let coordinator = self.persistentStoreCoordinator
        let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }

    /// Destroys and re-creates the persistent store. Not safe to use
    /// if any additional contexts have been created aside from our primary `managedObjectContext`.
    func clearPersistentStore() {
        if let store = self.persistentStoreCoordinator.persistentStores.first as? NSPersistentStore {
            let url = store.URL!

            var err: NSError?
            self.persistentStoreCoordinator.removePersistentStore(store, error: &err)
            NSFileManager.defaultManager().removeItemAtURL(url, error: &err)

            if let error = UserDataController.addPersistentStore(url, coordinator: self.persistentStoreCoordinator) {
                NSLog("Error re-adding store to PSC: %@", error)
            }
        }
    }

    // MARK: - Core Data Saving support

    private func saveContext () {
        let moc = self.managedObjectContext
        var error: NSError? = nil
        if moc.hasChanges && !moc.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }

    // MARK: - Session Bookmarks

    private func bookmarkSessionFetchRequest(session: Session) -> NSFetchRequest {
        let entityName = SessionBookmark.entityName
        let predicate = NSPredicate(format: "sessionID = %@", argumentArray: [session.sessionID])
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = predicate

        return fetchRequest
    }

    func isBookmarked(session: Session) -> Bool {
        let context = self.managedObjectContext
        let fetchRequest = self.bookmarkSessionFetchRequest(session)
        let bookmarked = context.countForFetchRequest(fetchRequest, error: nil) == 1
        return bookmarked
    }

    func bookmark(session: Session) {
        let context = self.managedObjectContext
        let entityName = SessionBookmark.entityName
        let bookmarkEntity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)!

        let fetchRequest = self.bookmarkSessionFetchRequest(session)
        let exists = context.countForFetchRequest(fetchRequest, error: nil) == 1
        if exists {
            return
        }

        let bookmark = SessionBookmark(entity: bookmarkEntity, insertIntoManagedObjectContext: context)
        bookmark.sessionID = session.sessionID
        self.saveContext()
    }

    func removeBookmark(session: Session) {
        let context = self.managedObjectContext
        let entityName = SessionBookmark.entityName
        let bookmarkEntity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)!

        let fetchRequest = self.bookmarkSessionFetchRequest(session)
        let bookmark = context.executeFetchRequest(fetchRequest, error: nil)?.first as? SessionBookmark
        if let bookmark = bookmark {
            context.deleteObject(bookmark)
            self.saveContext()
        }
    }
}
