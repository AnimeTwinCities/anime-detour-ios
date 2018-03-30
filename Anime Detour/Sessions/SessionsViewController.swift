//
//  SessionsViewController.swift
//  DevFest
//
//  Created by Brendon Justin on 11/23/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit
import os

/**
 Display SessionViewModels in a collection view.
 
 - seealso: `dataSource`
 */
class SessionsViewController: UICollectionViewController, FlowLayoutContaining {
    @IBInspectable var detailSegueIdentifier: String!
    @IBInspectable var tableViewControllerIdentifier: String!
    @IBOutlet var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet var stickyHeaderFlowLayout: StickyHeaderFlowLayout!
    
    /**
     A bar button item that allows jumping to approximately the current time in the session list.
     */
    @IBOutlet var nowButton: UIBarButtonItem?
    
    /**
     The source of data displayed in this view.
     
     If `dataSource` conforms to `FitlerableSessionDataSource`, we allow the user to search sessions.
     */
    var dataSource: (SessionDataSource & SessionStarsDataSource)? {
        didSet {
            dataSource?.sessionDataSourceDelegate = self
            dataSource?.sessionStarsDataSourceDelegate = self
            
            if isViewLoaded, let collectionView = collectionView, let dataSource = dataSource {
                dayScroller = SessionDayScroller(dataSource: dataSource, targetView: .collectionView(collectionView))
                addOrRemoveSearchController()
            }
        }
    }
    
    /**
     The source of speaker information, to show in session detail views.
     */
    var speakerDataSource: SpeakerDataSource?
    
    /**
     The repository to supply images for session detail views.
     */
    var imageRepository: ImageRepository?
    
    // MARK: - Day Segmented Control
    
    /**
     Show or hide the day display/selection header.
     */
    var isDayControlVisible: Bool = true {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            stickyHeaderFlowLayout.headerEnabled = isDayControlVisible
        }
    }
    
    /**
     Scrolls to sessions near specified times, if there are such sessions. Also works with our `daySegmentedControl`.
     */
    fileprivate var dayScroller: SessionDayScroller?
    
    /**
     A segmented control to allow jumping to the sessions for a particular day. Allows up to three days.
     */
    fileprivate var daySegmentedControl: UISegmentedControl? {
        didSet {
            dayScroller?.daySegmentedControl = daySegmentedControl
        }
    }
    
    /**
     The header view that shows the `daySegmentedControl`.
     */
    fileprivate var segmentedControlHeaderView: SegmentedControlCollectionReusableView? {
        didSet {
            daySegmentedControl = segmentedControlHeaderView?.segmentedControl
        }
    }
    
    // MARK: - Filtering/Searching
    
    /**
     Allow searching sessions via user-input strings.
     */
    fileprivate var filterString: String? {
        didSet {
            guard let filterString = filterString, !filterString.isEmpty else {
                filteringPredicates = []
                return
            }
            
            filteringPredicates = [.nameContains(filterString)]
        }
    }
    
    /**
     All of the filters that are active on the displayed sessions right now.
     */
    fileprivate var filteringPredicates: Set<FilterableSessionDataSourcePredicate> = [] {
        didSet {
            if let filterable = dataSource as? FilterableSessionDataSource {
                filterable.filteringPredicates = filteringPredicates
            }
        }
    }
    
    /**
     The search controller is the mechanism that allows users to input a string for searching sessions.
     */
    fileprivate let searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    // MARK: - Detail Presentation
    
    /**
     The currently displayed session detail view, if the user viewed a particular session from this view controller.
     */
    weak var currentDetailViewController: SessionDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let dataSource = dataSource else {
            assertionFailure("Expected a data source to have already been set")
            return
        }
        
        dayScroller = SessionDayScroller(dataSource: dataSource, targetView: .collectionView(collectionView!))
        
        stickyHeaderFlowLayout.headerEnabled = isDayControlVisible
        updateStickyHeaderLayoutTopOffset()
        collectionView?.register(SegmentedControlCollectionReusableView.self,
                                 forSupplementaryViewOfKind: StickyHeaderFlowLayout.StickyHeaderElementKind,
                                 withReuseIdentifier: SegmentedControlCollectionReusableView.reuseID)
        
        let days = dataSource.daysForAllSessions()
        dayScroller?.days = days
        
        if let nowButton = nowButton {
            let nowTitle = NSLocalizedString("Now", comment: "Now button title")
            nowButton.accessibilityLabel = nowTitle
            nowButton.accessibilityHint = NSLocalizedString("Jump to the current time", comment: "")
        }
        updateFlowLayoutItemWidth()
        
        setupSearchController()
        
        addOrRemoveSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFlowLayoutItemWidth(viewSize: view?.frame.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateLayoutOnTransition(toViewSize: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            self.updateStickyHeaderLayoutTopOffset()
        }, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch (segue.identifier, sender, segue.destination) {
        case (detailSegueIdentifier?, let cell as SessionCell, let destination as SessionDetailViewController):
            let indexPath = collectionView?.indexPath(for: cell)
            let viewModel = indexPath.map { return self.viewModel(at: $0) }
            let speakers: [SpeakerViewModel]
            if let viewModel = viewModel, let speakerDataSource = speakerDataSource {
                let speakerViewModels: [SpeakerViewModel] = viewModel.speakerIDs.compactMap(speakerDataSource.viewModel(forSpeakerID:))
                speakers = speakerViewModels
            } else {
                speakers = []
            }
            
            destination.delegate = self
            destination.imageRepository = imageRepository
            destination.viewModel = viewModel
            destination.speakers = speakers
            currentDetailViewController = destination
        default:
            break
        }
    }
    
    func updateFlowLayoutItemWidth(viewSize size: CGSize? = nil) {
        guard let flowLayout = flowLayout, let size = size else {
            return
        }
        
        let height = flowLayout.itemSize.height
        // 368 == 736 / 2, giving us more than one column only when our view is 736 wide or wider.
        // The iPhone 7 Plus screen is 736 pts tall, so in landscape, it will show two columns.
        let numberOfColumns = max(1, floor(size.width / 368))
        let impreciseWidth = size.width / numberOfColumns
        let width = floor(impreciseWidth)
        let cellSize = CGSize(width: width, height: height)
        flowLayout.itemSize = cellSize
        flowLayout.invalidateLayout()
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource?.numberOfSections ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfItems = dataSource?.numberOfItems(inSection: section) ?? 0
        return numberOfItems
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(for: indexPath) as SessionCell
        cell.viewModel = viewModel(at: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == StickyHeaderFlowLayout.StickyHeaderElementKind {
            let view = collectionView.dequeueSupplementaryView(ofKind: kind, for: indexPath) as SegmentedControlCollectionReusableView
            segmentedControlHeaderView = view

            // iOS Bug: In iOS 11, the sticky header shows behind section headers, despite its layout attributes
            // including a higher zIndex than the section headers.
            // Manually set the layer's zPosition to avoid this issue.
            let zPosition = collectionView.layoutAttributesForSupplementaryElement(ofKind: StickyHeaderFlowLayout.StickyHeaderElementKind, at: StickyHeaderFlowLayout.StickyHeaderIndexPath)?.zIndex
            view.layer.zPosition = CGFloat(zPosition ?? 0)
            return view
        }
        
        let view = collectionView.dequeueSupplementaryView(ofKind: kind, for: indexPath) as SessionHeaderCollectionReusableView
        view.timeLabel.text = dataSource!.title(forSection: indexPath.section)
        return view
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        dayScroller?.willDisplayItem(at: indexPath)
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        dayScroller?.scrollViewDidEndScrollingAnimation()
    }
    
    // MARK: UIResponder
    
    override func adr_toggleStarred(forSessionID identifier: String) {
        guard let dataSource = dataSource, let sessionIndexPath = dataSource.indexPathOfSession(withSessionID: identifier) else {
            return
        }

        let existingViewModel = dataSource.viewModel(at: sessionIndexPath)
        let updatedViewModel: SessionViewModel
        if existingViewModel.isStarred {
            updatedViewModel = dataSource.unstarSession(for: existingViewModel)
        } else {
            updatedViewModel = dataSource.starSession(for: existingViewModel)
        }
        assert(updatedViewModel.sessionID == identifier)
        
        if let cell = collectionView?.cellForItem(at: sessionIndexPath) as? SessionCell {
            cell.viewModel = updatedViewModel
        }
        
        if let detailVC = currentDetailViewController, detailVC.viewModel?.sessionID == identifier {
            detailVC.viewModel = updatedViewModel
        }
    }
}

private extension SessionsViewController {
    /**
     Toggle the `isStarred` status of the session for `viewModel`, using our `dataSource`.
     */
    func toggleStarred(for viewModel: SessionViewModel) {
        guard let dataSource = dataSource else {
            os_log("Trying to star or unstar a session, but we don't have a data source.")
            return
        }
        
        let identifier = viewModel.sessionID
        
        let updatedViewModel: SessionViewModel
        if viewModel.isStarred {
            updatedViewModel = dataSource.unstarSession(for: viewModel)
        } else {
            updatedViewModel = dataSource.starSession(for: viewModel)
        }
        assert(updatedViewModel.sessionID == identifier)
        
        if let sessionIndexPath = dataSource.indexPathOfSession(withSessionID: identifier), let cell = collectionView?.cellForItem(at: sessionIndexPath) as? SessionCell {
            cell.viewModel = updatedViewModel
        }
        
        if let detailVC = currentDetailViewController, detailVC.viewModel?.sessionID == viewModel.sessionID {
            detailVC.viewModel = updatedViewModel
        }
    }
    
    /**
     Perform initial setup of the search controller, setting its delegate, appearance, etc.
     */
    func setupSearchController() {
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self

        // iOS Bug: For whatever reason, on iOS 11, the search field is too high up in its superview.
        // Move it down manually.
        searchController.searchBar.searchFieldBackgroundPositionAdjustment = UIOffset(horizontal: 0, vertical: 7)
    }
    
    /**
     Add or remove the search controller, based on whether our data source supports filtering.
     */
    func addOrRemoveSearchController() {
        let allowsSearching: Bool
        
        if let _ = dataSource as? FilterableSessionDataSource {
            allowsSearching = true
        } else {
            allowsSearching = false
        }
        
        if allowsSearching {
            navigationItem.searchController = searchController
        } else {
            navigationItem.searchController = nil
        }
    }
    
    /// Update the top offset for our sticky header layout.
    func updateStickyHeaderLayoutTopOffset() {
        stickyHeaderFlowLayout.headerTopOffset = view.safeAreaInsets.top
    }
    
    /**
     Convenience method to get the view model at a given index path.
     */
    func viewModel(at indexPath: IndexPath) -> SessionViewModel {
        let viewModel = dataSource!.viewModel(at: indexPath)
        return viewModel
    }
    
    /**
     Using the day scroller, scroll to the first session which is currently in progress.
     */
    @IBAction func showUpcomingSessions() {
        let now = Date()
        // 1491620400 is 4/8/17 at 3AM UTC, which is 4/8/17 at 10 PM CDT
//        let now = Date(timeIntervalSince1970: 1491620400)
        
        guard let dayScroller = dayScroller else {
            assertionFailure("Expected to have a day scroller")
            return
        }
        
        if !dayScroller.scrollToFirstSession(atOrAfter: now, after: false) {
            // Show an alert saying what we'll do once the con starts
            let title = NSLocalizedString("‘Now’ Button", comment: "")
            let message = NSLocalizedString("During Anime Detour, use the ‘Now’ button to scroll the schedule to the current time.", comment: "")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let ok = UIAlertAction(title: NSLocalizedString("Got It", comment: ""), style: .cancel, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        } else {
            // Since we just started a scroll, update the day selector for the target date.
            if let idx = dayScroller.dayIndex(for: now) {
                daySegmentedControl?.selectedSegmentIndex = idx
            }
        }
    }
}

extension SessionsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text
        filterString = searchTerm
    }
}

extension SessionsViewController: SessionDataSourceDelegate {
    func sessionDataSourceDidUpdate(filtering: Bool) {
        // TODO: animate updates
        collectionView?.reloadData()
        
        if filtering {
            daySegmentedControl?.isEnabled = false
        } else {
            let days = dataSource?.daysForAllSessions()
            dayScroller?.days = days ?? []
            daySegmentedControl?.isEnabled = true
        }
    }
}

extension SessionsViewController: SessionStarsDataSourceDelegate {
    func sessionStarsDidUpdate(dataSource: SessionStarsDataSource) {
        // TODO: animate updates
        collectionView?.reloadData()
    }
}

extension SessionsViewController: SessionDetailViewControllerDelegate {
    func addSessionToSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController) {
        assert(!viewModel.isStarred, "Shouldn't be able to add a session if it is already starred.")
        toggleStarred(for: viewModel)
    }
    
    func removeSessionFromSchedule(for viewModel: SessionViewModel, sender: SessionDetailViewController) {
        assert(viewModel.isStarred, "Shouldn't be able to remove a session if it is not yet starred.")
        toggleStarred(for: viewModel)
    }
}


// MARK: - SessionDayScroller

/**
 Manages scrolling to days, and indicating the day of a displayed item, using a `UISegmentedControl`.
 The `UIScrollViewDelegate` method `scrollViewDidEndScrollingAnimation` for `targetView` MUST be
 forwarded to this class for the day indicator to update correctly.
 */
private class SessionDayScroller {
    enum TargetView {
        case collectionView(UICollectionView)
        case tableView(UITableView)
    }
    
    private let dataSource: SessionDataSource
    private let targetView: TargetView
    weak var daySegmentedControl: UISegmentedControl? {
        didSet {
            guard let daysControl = daySegmentedControl else {
                oldValue?.removeTarget(self, action: nil, for: .valueChanged)
                return
            }
            
            daysControl.addTarget(self, action: #selector(SessionDayScroller.goToDay(_:)), for: UIControlEvents.valueChanged)
            updateSegmentedControlDays()
        }
    }
    
    /**
     An array of dates, set to midnight, of each day of the con.
     */
    var days: [Date] = [] {
        didSet {
            updateSegmentedControlDays()
        }
    }
    
    /// `true` indicates that the view is currently scrolling to the first item on
    /// a particular day.
    private var scrollingToDay = false
    
    private var sectionOfLatestDisplayedItem: Int = 0 {
        didSet {
            guard sectionOfLatestDisplayedItem != oldValue else {
                return
            }
            
            guard let segmentedControl = daySegmentedControl else {
                return
            }
            
            if let dateForSection = date(forSection: sectionOfLatestDisplayedItem), let idx = dayIndex(for: dateForSection) {
                segmentedControl.selectedSegmentIndex = idx
            }
        }
    }
    
    /**
     - parameter daySegmentedControl: The control using which the day of the latest displayed `Session` will be indicated.
     */
    init(dataSource: SessionDataSource, targetView: TargetView) {
        self.dataSource = dataSource
        self.targetView = targetView
    }
    
    /**
     Finds the index of the date in `days` which is the same day as `date`.
     
     - returns: An index, or `nil` if no matching date was found.
     */
    func dayIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        for (idx, day) in days.enumerated() {
            if calendar.isDate(date, inSameDayAs: day) {
                return idx
            }
        }
        
        return nil
    }
    
    /**
     Find the index path of the first Session with a start time of `date` (or later),
     based on our `dataSource`'s sections.
     
     Find session with a start time of `date` or *before*, logic reversed if `after` is `false`.
     */
    private func indexPathOfSection(for date: Date, after: Bool = true) -> IndexPath? {
        let method = after ? dataSource.firstSection(atOrAfter:) : dataSource.lastSection(atOrBefore:)
        if let section = method(date) {
            return IndexPath(item: 0, section: section)
        } else {
            return nil
        }
    }
    
    private func updateSegmentedControlDays() {
        // Set the names of the days on the day chooser segmented control
        guard let daysControl = daySegmentedControl else {
            return
        }
        
        let formatter = DateFormatter()
        // The full name of the day of the week, e.g. Monday
        formatter.dateFormat = "EEEE"
        
        // Try to preserve the selected segment index
        let previousSelectedIndex = daysControl.selectedSegmentIndex
        
        daysControl.removeAllSegments()
        for (idx, date) in days.enumerated() {
            let title = formatter.string(from: date)
            daysControl.insertSegment(withTitle: title, at: idx, animated: false)
        }
        
        if previousSelectedIndex != -1, previousSelectedIndex < days.count {
            daysControl.selectedSegmentIndex = previousSelectedIndex
        } else {
            daysControl.selectedSegmentIndex = 0
        }
    }
    
    /**
     The start date for `Session`s in a given section.
     */
    func date(forSection section: Int) -> Date? {
        var indexPath: IndexPath
        switch targetView {
        case .collectionView:
            indexPath = IndexPath(item: 0, section: section)
        case .tableView:
            indexPath = IndexPath(row: 0, section: section)
        }
        
        let session = dataSource.viewModel(at: indexPath)
        return session.start
    }
    
    /**
     Scroll to the first session at or after `date`. If `after` is `false`, scroll to the first session at or *before* `date`.
     
     - returns: `true` if scrolling was done, `false` if not.
     */
    @discardableResult
    func scrollToFirstSession(atOrAfter date: Date, after: Bool = true) -> Bool {
        guard let indexPath = indexPathOfSection(for: date, after: after) else {
            return false
        }
        
        switch targetView {
        case let .collectionView(cv):
            if let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                if cv.collectionViewLayout.collectionViewContentSize.height < cv.bounds.height {
                    // Don't scroll if the entire contents are already showing
                    break
                }
                
                let yCoordOfFirstView = flowLayout.yCoordinateForFirstItemInSection(indexPath.section)
                var offset = cv.contentOffset
                // Subtract the top content inset to take into account anything that floats at
                // the top of the collection view, e.g. a navigation bar or in our case,
                // the day selector.
                offset.y = yCoordOfFirstView - cv.contentInset.top
                cv.setContentOffset(offset, animated: true)
            } else {
                cv.scrollToItem(at: indexPath, at: .top, animated: true)
            }
        case let .tableView(tv):
            tv.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
        scrollingToDay = true
        
        return true
    }
    
    func willDisplayItem(at indexPath: IndexPath) {
        guard !scrollingToDay else {
            return
        }
        
        sectionOfLatestDisplayedItem = indexPath.section
        return
    }
    
    // MARK: - Scroll View Delegate
    
    func scrollViewDidEndScrollingAnimation() {
        // Delay un-setting `scrollingToDay` so we don't depend on ordering
        // relative to `willDisplayItemAtIndexPath(_:)`.
        DispatchQueue.main.async {
            self.scrollingToDay = false
        }
    }
    
    // MARK: - Received actions
    
    @IBAction @objc func goToDay(_ sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex
        let day = days[selectedIdx]
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = 9
        let dayAt9AM = calendar.date(from: components)!
        scrollToFirstSession(atOrAfter: dayAt9AM)
    }
}
