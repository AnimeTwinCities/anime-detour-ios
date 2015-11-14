//
//  AnalyticsScreen.swift
//  Anime Detour
//
//  Created by Brendon Justin on 11/14/15.
//  Copyright © 2015 Anime Detour. All rights reserved.
//

import Foundation

protocol AnalyticsScreen {
    /**
     The name to log for a display event for a screen, usually a UIViewController.
     */
    var screenName: String { get }
}
