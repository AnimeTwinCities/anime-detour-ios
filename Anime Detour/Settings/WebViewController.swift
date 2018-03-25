//
//  WebViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/21/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var url: URL!

    /// Convenience String getter/setter that uses `url` internally
    @IBInspectable var urlString: String! {
        set {
            url = URL(string: newValue)
        }
        get {
            return url.absoluteString
        }
    }

    fileprivate var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        addWebView()
        load(url)
    }

    fileprivate func addWebView() {
        // Create and add a web view to our view
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        self.webView = webView

        let bindings = ["webView" : webView]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[webView]|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|", options: [], metrics: nil, views: bindings)

        view.addConstraints(hConstraints + vConstraints)
    }

    fileprivate func load(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
