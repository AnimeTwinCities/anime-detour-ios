//
//  Acknowledgements.swift
//  Anime Detour
//
//  Created by Brendon Justin on 3/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import Foundation

import FXForms

/**
Form that sends user to the acknowledgements section of the Settings app.
Requires that a responder in the responder chain responds to `showSettings`.
*/
@objc(Acknowledgements) public final class Acknowledgements: NSObject, FXForm {
    public func extraFields() -> [Any]! {
        return [
            [ FXFormFieldTitle : "View Acknowledgements", FXFormFieldAction : "showSettings" ],
        ]
    }
}
