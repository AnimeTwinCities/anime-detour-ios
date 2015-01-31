//
//  GuestViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/25/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

import AnimeDetourAPI

class GuestViewController: UIViewController {

    lazy var imageSession = NSURLSession.sharedSession()
    var guestViewModel: GuestViewModel!

    private var guestView: GuestView {
        return self.view as GuestView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.guestView.viewModel = self.guestViewModel
    }

}
