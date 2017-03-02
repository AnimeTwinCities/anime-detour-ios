//
//  GoogleSignInViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 1/14/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit

import GoogleSignIn

class GoogleSignInViewController: UIViewController, GIDSignInUIDelegate {
    // The top constraint of our top-most subview
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var signInButton: GIDSignInButton!
    @IBOutlet var signOutButton: UIButton!
    
    var isSignedIn = false {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            signInButton.isEnabled = !isSignedIn
            signOutButton.isEnabled = isSignedIn
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Sign In", comment: "Google sign in view controller title")
        descriptionLabel.text = NSLocalizedString("Sign in with Google to sync your agenda with the DevFestMN web site.", comment: "Describe why one would sign in with Google.")
        signOutButton.setTitle(NSLocalizedString("Sign Out", comment: "Sign out button for the Google sign in view"), for: .normal)
        
        signInButton.isEnabled = !isSignedIn
        signOutButton.isEnabled = isSignedIn
        
        GIDSignIn.sharedInstance().uiDelegate = self
        
        dev_updateAppearance()
        dev_registerForAppearanceUpdates()
    }
    
    override func dev_updateAppearance() {
        super.dev_updateAppearance()
        
        topConstraint.constant = .dev_contentOutsideVerticalMargin
        descriptionLabel.font = .dev_contentFont
    }
    
    @IBAction func signOut(_ sender: Any) {
        GIDSignIn.sharedInstance().disconnect()
    }
}
