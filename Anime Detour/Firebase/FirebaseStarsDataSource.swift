//
//  FirebaseStarsDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/26/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation
import FirebaseDatabase

/**
 Provides the IDs of Sessions that have been starred in Firebase.
 Requires the user to authenticate with Firebase, and that the method
 `setFirebaseUserID(_:, shouldMergeLocalAndRemoteStarsOnce:)` be called
 to sync starred IDs with Firebase.
 
 Also persists the IDs of Sessions which it has been told are starred to disk,
 so they can be available even when not authenticated with Firebase.
 */
final class FirebaseStarsDataSource: SessionStarsDataSource {
    fileprivate let databaseReference: FIRDatabaseReference
    private let defaultsPersister = UserDefaultsPersister()
    
    weak var sessionStarsDataSourceDelegate: SessionStarsDataSourceDelegate?

    /// The IDs of sessions that have been starred.
    fileprivate(set) var starredSessionIDs: Set<String> = [] {
        didSet {
            // Take no action if the value hasn't actually changed.
            guard starredSessionIDs != oldValue else {
                return
            }
            
            sessionStarsDataSourceDelegate?.sessionStarsDidUpdate(dataSource: self)
            if let firebaseUserID = firebaseUserID {
                updateStarsInFirebase(userID: firebaseUserID)
            }
            
            // Also persist starred IDs to disk.
            defaultsPersister.starredSessionIDs = starredSessionIDs
        }
    }
    
    /**
     - seealso: `setFirebaseUserID(_:, shouldMergeLocalAndRemoteStarsOnce:)`
     */
    fileprivate var firebaseUserID: String?
    
    /**
     - seealso: `setFirebaseUserID(_:, shouldMergeLocalAndRemoteStarsOnce:)`
     */
    fileprivate var firebaseObservingHandle: UInt?
    
    init(databaseReference: FIRDatabaseReference = FIRDatabase.database().reference()) {
        self.databaseReference = databaseReference
        starredSessionIDs = defaultsPersister.starredSessionIDs
    }
    
    deinit {
        if let observingHandle = firebaseObservingHandle {
            databaseReference.removeObserver(withHandle: observingHandle)
        }
    }
    
    // MARK: - SessionStarsDataSource
    
    func isStarred(viewModel: SessionViewModel) -> Bool {
        let didFindID = starredSessionIDs.contains(viewModel.sessionID)
        return didFindID
    }
    
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel {
        // Update our starred sessions, create a new view model, and return the new view model
        starredSessionIDs.insert(viewModel.sessionID)
        
        var vm = viewModel
        vm.isStarred = true
        return vm
    }
    
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel {
        // Update our starred sessions, create a new view model, and return the new view model
        starredSessionIDs.remove(viewModel.sessionID)
        
        var vm = viewModel
        vm.isStarred = false
        return vm
    }
    
    /**
     Set (or remove) the user's Firebase ID, so we can sync (or stop syncing) their starred sessions to Firebase.
     */
    func setFirebaseUserID(_ userID: String?, shouldMergeLocalAndRemoteStarsOnce: Bool) {
        if let handle = firebaseObservingHandle {
            databaseReference.removeObserver(withHandle: handle)
        }
        
        firebaseUserID = userID
        if let firebaseUserID = firebaseUserID {
            registerForObservingAgenda(forUserWithID: firebaseUserID, shouldMergeLocalAndRemoteStartsOnce: shouldMergeLocalAndRemoteStarsOnce)
        }
    }
}

private extension FirebaseStarsDataSource {
    func updateStarsInFirebase(userID: String) {
        var starsDict: [String:Any] = [:]
        for sessionID in starredSessionIDs {
            starsDict[sessionID] = true
        }
        
        databaseReference.child("favorites").child("ad-2017").child(userID).setValue(starsDict)
    }
    
    func registerForObservingAgenda(forUserWithID userID: String, shouldMergeLocalAndRemoteStartsOnce: Bool) {
        var shouldMerge = shouldMergeLocalAndRemoteStartsOnce
        
        firebaseObservingHandle = databaseReference.child("favorites").child("ad-2017").child(userID).observe(.value) { [weak self] (snapshot: FIRDataSnapshot) in
            // Assume a format like [{ "sessionIDGoesHere" : true }, { "anotherSessionID" : true }]
            guard let strongSelf = self, let sessionIDsDicts = snapshot.value as? [String:Any] else {
                return
            }
            
            let sessionIDs = sessionIDsDicts.keys
            let firebaseStarredSessionIDs = Set(sessionIDs)
            let starredSessionIDs: Set<String>
            if shouldMerge {
                shouldMerge = false
                starredSessionIDs = strongSelf.starredSessionIDs.union(firebaseStarredSessionIDs)
            } else {
                starredSessionIDs = firebaseStarredSessionIDs
            }
            strongSelf.starredSessionIDs = starredSessionIDs
        }
    }
}


/**
 This is terrible. Don't copy this. Make something better instead of being lazy.
 */
private class UserDefaultsPersister {
    static let StarredSessionIDsKey = "FirebaseStarsDataSource.StarredSessionIDs"
    
    var starredSessionIDs: Set<String> {
        get {
            let ids = UserDefaults.standard.array(forKey: UserDefaultsPersister.StarredSessionIDsKey) as? [String]
            return Set(ids ?? [])
        }
        set {
            let ids = Array(newValue)
            UserDefaults.standard.setValue(ids as NSArray, forKey: UserDefaultsPersister.StarredSessionIDsKey)
        }
    }
}
