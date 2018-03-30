//
//  Settings.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import FXForms

@objcMembers final class Settings: NSObject, FXForm {
    let acknowledgements: Acknowledgements
    let sessions: SessionSettings
    
    init(acknowledgements: Acknowledgements, sessionSettingsForm: SessionSettings) {
        self.acknowledgements = acknowledgements
        self.sessions = sessionSettingsForm
        
        super.init()
    }
    
    func acknowledgementsField() -> NSDictionary {
        return [ FXFormFieldInline : NSNumber(value: true) ]
    }
    
    func sessionsField() -> NSDictionary {
        return [ FXFormFieldInline : NSNumber(value: true) ]
    }
}
