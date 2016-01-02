//
//  GuestDetailTableViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/31/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit

class GuestDetailTableViewController: UITableViewController, UIWebViewDelegate, GuestViewModelDelegate {
    var guestViewModel: GuestViewModel!
    
    private var imageHeaderView: ImageHeaderView!
    private var bioWebViewHeight: CGFloat?
    private var bioWebviewLoadInitiated = false

    @IBInspectable var bioIdentifier: String!
    @IBInspectable var nameIdentifier: String!

    /// The aspect ratio (width / height) of the photo image view.
    @IBInspectable var photoAspect: CGFloat = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.guestViewModel.delegate = self
        
        self.imageHeaderView = self.tableView.tableHeaderView as! ImageHeaderView
        self.imageHeaderView.imageView.image = self.guestViewModel.hiResPhoto(true, lowResPhotoPlaceholder: true)
        
        self.updateHeaderSize()
    }
    
    /// Adjust the frame of the header view to maintain our target aspect ratio.
    private func updateHeaderSize() {
        let headerFrame = self.imageHeaderView.frame
        let newHeight = round(self.view.frame.width / self.photoAspect)
        let newFrame = CGRect(origin: headerFrame.origin, size: CGSize(width: headerFrame.width, height: newHeight))
        self.imageHeaderView.frame = newFrame
    }
    
    /// Adjust the top constraint of the image header view's image,
    /// so more of the image is visible if the user over-scrolls the table view.
    private func updateHeaderImageTopConstraint() {
        let verticalOffset = self.tableView.contentOffset.y
        let verticalInset = self.tableView.contentInset.top
        
        let total = verticalOffset + verticalInset
        
        // If `verticalOffset` is < 0, i.e. the table view was overscrolled down such that the
        // top of its content is lower on the screen than it would be if the user were not touching
        // the screen, then extend the top of the image header view's image view to fill the empty space.
        if total < 0 {
            self.imageHeaderView.imageViewTopConstraint.constant = total
        } else {
            self.imageHeaderView.imageViewTopConstraint.constant = 0
        }
    }

    private func configure(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        switch cell.reuseIdentifier {
        case .Some(self.nameIdentifier):
            cell.textLabel?.text = self.guestViewModel.name
        case .Some(self.bioIdentifier):
            let webView = cell.contentView.subviews.filter { return $0 is UIWebView }.first as! UIWebView
            webView.delegate = self
            webView.scrollView.scrollEnabled = false
            if !self.bioWebviewLoadInitiated {
                webView.loadHTMLString(self.guestViewModel.bio, baseURL: nil)
                self.bioWebviewLoadInitiated = true
            }
        default:
            fatalError("Unexpected reuse identifier: \(cell.reuseIdentifier). Expected a match against one of our xIdentifier properties.")
        }
    }
    
    // MARK: - Scroll view delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.updateHeaderImageTopConstraint()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        self.configure(cell, atIndexPath: indexPath)

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let row = GuestDetailTableViewCellRow(row: indexPath.row) else {
            fatalError("Unexpected row number: \(indexPath.row) in guest detail view.")
        }
        
        switch row {
        case .Name:
            return 44
        case .Bio:
            return self.bioWebViewHeight ?? tableView.frame.height - 344
        }
    }

    // MARK: - Web view delegate

    func webViewDidFinishLoad(webView: UIWebView) {
        let size = webView.sizeThatFits(CGSize(width: webView.frame.width, height: CGFloat.max))

        // Calling `beginUpdates` and then `endUpdates` makes the table view reload cells,
        // getting our calculated cell height.
        self.tableView.beginUpdates()
        self.bioWebViewHeight = size.height
        self.tableView.endUpdates()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // Loading the guest's bio has a URL of about:blank.
        // Shunt other URLs to the app delegate, which will open them in the appropriate apps.
        if request.URL == NSURL(string: "about:blank") {
            return true
        } else {
            UIApplication.sharedApplication().openURL(request.URL!)
            return false
        }
    }

    // MARK: - Guest view model delegate

    func didDownloadPhoto(viewModel: GuestViewModel, photo: UIImage, hiRes: Bool) {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
            self.configure(cell, atIndexPath: indexPath)
        }
    }

    func didFailDownloadingPhoto(viewModel: GuestViewModel, error: NSError) {
        // empty
    }

}

/**
 Cases correspond to data expected to be displayed for a given row.
 */
private enum GuestDetailTableViewCellRow {
    case Name
    case Bio
    
    init?(row: Int) {
        switch row {
        case 0:
            self = .Name
        case 1:
            self = .Bio
        default:
            return nil
        }
    }
}
