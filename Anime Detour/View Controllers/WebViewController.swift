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
    var url: NSURL!

    /// Convenience String getter/setter that uses `url` internally
    @IBInspectable var urlString: String! {
        set {
            url = NSURL(string: newValue)
        }
        get {
            return url.absoluteString
        }
    }

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        addWebView()
        load(url)
    }

    private func addWebView() {
        // Create and add a web view to our view
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        self.webView = webView

        let bindings = ["webView" : webView]
        let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|[webView]|", options: [], metrics: nil, views: bindings)
        let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[webView]|", options: [], metrics: nil, views: bindings)

        view.addConstraints(hConstraints + vConstraints)
    }

    private func load(url: NSURL) {
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }
}
