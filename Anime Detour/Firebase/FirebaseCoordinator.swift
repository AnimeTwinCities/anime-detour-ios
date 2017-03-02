//
//  FirebaseCoordinator.swift
//  DevFest
//
//  Created by Brendon Justin on 12/21/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn

/**
 Coordinator that sets up Firebase when `start` is called.
 */
class FirebaseCoordinator {
    /**
     The firebase database we're using.
     */
    private(set) var firebaseDatabase: FIRDatabase?
    
    var googleClientID: String? {
        return FIRApp.defaultApp()?.options.clientID
    }
    
    var firebaseUserID: String? {
        return FIRAuth.auth()?.currentUser?.uid
    }
    
    /// A callback to run when we've finished trying to sign in, indicating failure if the error parameter
    /// is non-nil, else success. Only one of the parameters should be `nil` at a time.
    var signInCallback: (FIRUser?, Error?) -> Void = { _ in }
    
    func start() {
        FIRApp.configure()
        
        firebaseDatabase = FIRDatabase.database()
        firebaseDatabase?.persistenceEnabled = true
    }
    
    func signIn(forGoogleUser user: GIDGoogleUser) {
        guard let authentication = user.authentication else {
            NSLog("Expected a non-nil `authentication` on signed in Google user.")
            return
        }
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if let error = error {
                NSLog("Error authenticating with Firebase after signing in to Google: \(error)")
                self.signInCallback(nil, error)
                return
            }
            
            self.signInCallback(user, nil)
        }
    }
    
    func disconnectSignIn(forGoogleUser user: GIDGoogleUser) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch {
            NSLog("Error signing out. Perhaps no user was signed in to begin with?\n\(error)")
        }
    }
}
