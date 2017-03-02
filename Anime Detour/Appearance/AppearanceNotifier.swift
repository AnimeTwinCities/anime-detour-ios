//
//  AppearanceNotifier.swift
//  DevFest
//
//  Created by Brendon Justin on 11/27/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit

extension Notification.Name {
    public static let ADRAppearanceDidChange: Notification.Name = Notification.Name(rawValue: "ADRAppearanceDidChange")
}

/**
 Posts `Notification.Name.ADRAppearanceDidChange` notifications when any colors, fonts, etc, are changed.
 
 Access the `shared` static member to create an instance for the app.
 */
final class AppearanceNotifier: NSObject {
    static let shared = AppearanceNotifier()
    private let observerToken: AnyObject
    
    private override init() {
        observerToken = NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange, object: nil, queue: nil) { _ in
            NotificationCenter.default.post(name: .ADRAppearanceDidChange, object: nil)
        }
        
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(observerToken)
    }
}

extension NSObject {
    @objc private func dev_apperanceNeedsUpdate(notification: Notification) {
        dev_updateAppearance()
    }
    
    /**
     Register to be informed when appearance settings, such as fonts and colors, are updated.
     
     `dev_updateAppearance()` will be called when such an event occurs.
     */
    final func dev_registerForAppearanceUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(dev_apperanceNeedsUpdate(notification:)), name: .ADRAppearanceDidChange, object: nil)
    }
    
    /**
     One of the convenience methods for responding to appearance updates.
     
     - SeeAlso: `dev_registerForAppearanceUpdates()`
     */
    func dev_updateAppearance() {
        // empty by default
    }
}
