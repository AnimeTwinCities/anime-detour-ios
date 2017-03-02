//
//  SessionCollectionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

import AnimeDetourDataModel
import AnimeDetourAPI

class SessionCollectionViewController: UICollectionViewController {
    fileprivate var imagesURLSession = URLSession.shared
    lazy fileprivate var refreshingTableViewController: UITableViewController = UITableViewController()
    fileprivate var refreshing: Bool = false {
        didSet {
            if refreshing {
                refreshControl.beginRefreshing()
            } else {
                refreshControl.endRefreshing()
            }
        }
    }
    
    /// Refresh control added to a dummy table view controller for the table view's management functionality
    lazy fileprivate var refreshControl: UIRefreshControl = { () -> UIRefreshControl in
        let control = UIRefreshControl()
        self.refreshingTableViewController.refreshControl = control
        
        control.addTarget(self, action: #selector(SessionCollectionViewController.refreshSessions(_:)), for: UIControlEvents.valueChanged)
        
        return control
    }()
    
    // MARK: Core Data
    
    /// Fetched results controller over `Session`s.
    lazy fileprivate var fetchedResultsController: NSFetchedResultsController<Session> = { () -> NSFetchedResultsController<Session> in
        let sessionsFetchRequest = self.sessionsFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: AppDelegate.persistentContainer.viewContext, sectionNameKeyPath: Session.Keys.startTime.rawValue, cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()
    
    /// Category name for which the Session list will be filtered.
    /// Updating this property will update our `title`.
    /// Must not be changed before `fetchedResultsController` is created.
    fileprivate var filteredCategory: SelectedSessionCategory = .all {
        didSet {
            guard filteredCategory != oldValue else {
                return
            }
            
            navigationItem.title = filteredTitle(filteredCategory)
            
            fetchedResultsController.fetchRequest.predicate = completePredicate
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                let error = error as NSError
                let errorDesc = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Unknown error"
                print("Error performing Session fetch: %@", errorDesc)
            }
            
            collectionView!.reloadData()
        }
    }
    
    fileprivate var completePredicate: NSPredicate? {
        let bookmarkedPredicate: NSPredicate? = nil // needs to be rethought since the bookmarked status of a Session is not on the Session itself
        var predicates = [NSPredicate]()
        if let filterPredicate = filteredSessionsPredicate {
            predicates.append(filterPredicate)
        }
        if let bookmarkedPredicate = bookmarkedPredicate {
            predicates.append(bookmarkedPredicate)
        }
        let completePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return completePredicate
    }
    fileprivate var filteredSessionsPredicate: NSPredicate? {
        switch filteredCategory {
        case .all:
            return nil
        case let .category(category):
            let categoryName = category.name
            let begins = NSPredicate(format: "\(Session.Keys.category.rawValue) BEGINSWITH %@", categoryName)
            let contains = NSPredicate(format: "\(Session.Keys.category.rawValue) CONTAINS %@", ", " + categoryName + ",")
            let ends = NSPredicate(format: "\(Session.Keys.category.rawValue) ENDSWITH %@", ", " + categoryName)
            let pred = NSCompoundPredicate(orPredicateWithSubpredicates: [begins, contains, ends])
            return pred
        }
    }
    lazy fileprivate var fetchedResultsControllerDelegate: CollectionViewFetchedResultsControllerDelegate = {
        let delegate = CollectionViewFetchedResultsControllerDelegate()
        delegate.collectionView = self.collectionView!
        return delegate
    }()
    
    /**
     Fetch request for all Sessions, sorted by start time then name. Creates a new fetch request on every access.
     */
    fileprivate var sessionsFetchRequest: NSFetchRequest<Session> {
        get {
            let sortDescriptors = [NSSortDescriptor(key: Session.Keys.startTime.rawValue, ascending: true), NSSortDescriptor(key: Session.Keys.name.rawValue, ascending: true)]
            let sessionsFetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }
    
    // MARK: Handoff
    
    /**
    Session ID to display in a `SessionViewController` following a Handoff.
    Should be reset to `nil` after Handoff.
    */
    fileprivate var handoffSessionID: String?
    
    // MARK: Collection view
    
    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    lazy fileprivate var dataSource: SessionDataSource = SessionDataSource(fetchedResultsController: self.fetchedResultsController, cellDelegate: self, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession)
    
    // MARK: Day indicator
    
    lazy fileprivate var dayScroller: SessionDayScroller = SessionDayScroller(fetchedResultsController: self.fetchedResultsController, timeZone: self.timeZone, targetView: .collectionView(self.collectionView!))
    fileprivate var timeZone: TimeZone = TimeZone(identifier: "America/Chicago")! // hard-coded for Anime-Detour
    
    // MARK: Controls
    
    @IBOutlet var nowButton: UIBarButtonItem? {
        didSet {
            nowButton?.accessibilityLabel = "Now"
            nowButton?.accessibilityHint = "Jump to the current time"
        }
    }
    
    @IBOutlet var daySegmentedControl: UISegmentedControl? {
        didSet {
            dayScroller.daySegmentedControl = daySegmentedControl
        }
    }
    
    // MARK: Reuse identifiers
    
    fileprivate var dayControlHeaderReuseIdentifier: String = "dayControlHeaderReuseIdentifier"
    
    // MARK: Segue identifiers
    
    @IBInspectable var detailSegueIdentifier: String!
    @IBInspectable var filterSegueIdentifier: String!
    @IBInspectable var searchSegueIdentifier: String!
    
    // MARK: Collection view sizing
    
    fileprivate var traitCollectionAfterCurrentTransition: UITraitCollection?
    fileprivate var lastDisplayedTraitCollection: UITraitCollection!
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Schedule"
        navigationItem.title = filteredTitle(filteredCategory)
        
        let collectionView = self.collectionView!
        
        addRefreshControl()
        
        collectionView.register(SegmentedControlCollectionReusableView.self, forSupplementaryViewOfKind: StickyHeaderFlowLayout.StickyHeaderElementKind, withReuseIdentifier: dayControlHeaderReuseIdentifier)
        
        updateStickyHeaderLayoutTopOffset()
        updateScrollViewScrollerTopInsetForStickyHeader()
        
        dataSource.prepareCollectionView(collectionView)
        fetchedResultsControllerDelegate.customizer = dataSource
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let error = error as NSError
            NSLog("Error fetching sessions: %@", error)
        }
        
        setFlowLayoutCellSizes(collectionView, forLayoutSize: collectionView.frame.size)
        lastDisplayedTraitCollection = traitCollection
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateStickyHeaderLayoutTopOffset()
        
        // Possibly update cell sizes. Belongs in `viewDidAppear:`, as the
        // trait collection is sometimes not up to date in `viewWillAppear:`.
        updateCellSizesIfNecessary()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let collectionView = self.collectionView!
        setFlowLayoutCellSizes(collectionView, forLayoutSize: size)
        
        traitCollectionAfterCurrentTransition = nil
        lastDisplayedTraitCollection = traitCollection
        
        coordinator.animate(alongsideTransition: { _ in self.updateStickyHeaderLayoutTopOffset() }, completion: nil)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        traitCollectionAfterCurrentTransition = newCollection
    }
    
    // MARK: - UIResponder
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        guard let sessionID = activity.userInfo?[SessionViewController.sessionActivitySessionIDKey] as? String else {
            return
        }
        
        let fetchRequest = NSFetchRequest<Session>(entityName: Session.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Session.Keys.sessionID.rawValue, sessionID)
        let count = try? fetchedResultsController.managedObjectContext.count(for: fetchRequest)
        guard count == 1 else {
            // don't do anything, since we don't have the session for the ID that we received
            return
        }
        
        handoffSessionID = sessionID
        performSegue(withIdentifier: detailSegueIdentifier, sender: self)
    }
    
    // MARK: - Show next sessions that haven't yet started
    
    /// Scroll to the Session that started closest to, but not after, the current time.
    @IBAction fileprivate func showUpcomingSessions() {
        let now = Date()
        // 1461380400 is 4/23/16 at 3AM UTC, which is 4/22/16 at 10 PM CDT
//        let now = NSDate(timeIntervalSince1970: 1461380400)
        
        if !dayScroller.scroll(now, after: false) {
            // Show an alert saying what we'll do once the con starts
            let alert = UIAlertController(title: "‘Now’ Button", message: "During Anime Detour, use the ‘Now’ button to scroll the schedule to the current time.", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Got It", style: .cancel, handler: { _ in alert.dismiss(animated: true, completion: nil) })
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        } else {
            // Since we just started a scroll, update the day selector for the target date.
            if let idx = dayScroller.dayIndex(now) {
                daySegmentedControl?.selectedSegmentIndex = idx
            }
        }
    }
    
    // MARK: - Collection view layout support
    
    fileprivate func updateCellSizesIfNecessary() {
        guard traitCollection != lastDisplayedTraitCollection else {
            return
        }
        
        let collectionView = self.collectionView!
        setFlowLayoutCellSizes(collectionView, forLayoutSize: collectionView.frame.size)
        lastDisplayedTraitCollection = traitCollection
    }
    
    /// Update the top offset for our layout, if it is a `StickyHeaderFlowLayout`.
    fileprivate func updateStickyHeaderLayoutTopOffset() {
        guard let stickyHeaderLayout = collectionViewLayout as? StickyHeaderFlowLayout else {
            return
        }
        
        // topLayoutGuide doesn't work for our purposes with a translucent navigation bar
        if let navBar = navigationController?.navigationBar , navBar.isTranslucent {
            stickyHeaderLayout.headerTopOffset = navBar.frame.maxY
        } else {
            stickyHeaderLayout.headerTopOffset = topLayoutGuide.length
        }
    }
    
    /// Update the scroll view scroller to be below the sticky header
    fileprivate func updateScrollViewScrollerTopInsetForStickyHeader() {
        let collectionView = self.collectionView!
        let insets = collectionView.scrollIndicatorInsets
        var newInsets = insets
        if let stickyHeaderLayout = collectionViewLayout as? StickyHeaderFlowLayout {
            newInsets.top = stickyHeaderLayout.headerHeight
        } else {
            newInsets.top = 0
        }
        
        collectionView.scrollIndicatorInsets = newInsets
    }
    
    /// Update the sizes of our collection view items based on the view's trait collection.
    fileprivate func setFlowLayoutCellSizes(_ collectionView: UICollectionView, forLayoutSize layoutSize: CGSize) {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let horizontalSpacing = layout.minimumInteritemSpacing
        
        let traitCollection = traitCollectionAfterCurrentTransition ?? collectionView.traitCollection
        let viewWidth = layoutSize.width
        
        var itemSize = layout.itemSize
        
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact {
            itemSize.width = viewWidth
        } else {
            // Assume .Regular
            let minCellWidth: CGFloat = 300 + horizontalSpacing
            let cellsPerRow = floor(viewWidth / minCellWidth)
            // `floor` to ensure cell widths are integral
            let widthPerCell = floor((viewWidth - (cellsPerRow - 1) * horizontalSpacing) / cellsPerRow)
            itemSize.width = widthPerCell
        }
        
        layout.itemSize = itemSize
    }
    
    // MARK: - Filtering
    
    func filteredTitle(_ filteredSessionType: SelectedSessionCategory) -> String {
        let unfilteredTitle = "Sessions"
        switch filteredCategory {
        case .all:
            return unfilteredTitle
        case let .category(category):
            return category.name
        }
    }
    
    // MARK: - Refreshing
    
    /**
     Add the refresh control to the collection view.
     
     - Note: Also sets `alwaysBounceVertical` on the collection view, so it may be refreshed event
     when empty.
     */
    fileprivate func addRefreshControl() {
        let collectionView = self.collectionView!
        collectionView.addSubview(refreshControl)
        
        collectionView.alwaysBounceVertical = true
        
        // Cheat and move the refresh control's bounds down, below the day selector header
        var headerHeight: CGFloat
        if let stickyHeaderLayout = collectionViewLayout as? StickyHeaderFlowLayout {
            headerHeight = stickyHeaderLayout.headerHeight
        } else {
            headerHeight = 50
        }
        var refreshBounds = refreshControl.bounds
        refreshBounds = refreshBounds.offsetBy(dx: 0, dy: -headerHeight)
        refreshControl.bounds = refreshBounds
        
        refreshControl.layer.zPosition = -1
    }
    
    @objc fileprivate func refreshSessions(_ sender: AnyObject?) {
        // empty
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case detailSegueIdentifier?:
            let detailVC = segue.destination as! SessionViewController
            let indexPath: IndexPath?
            let selectedSessionID: String
            if let cell = sender as? UICollectionViewCell {
                indexPath = collectionView?.indexPath(for: cell)
                let selectedSession = indexPath.map(dataSource.sessionAt)!
                selectedSessionID = selectedSession.sessionID
            } else if sender as? SessionCollectionViewController === self {
                // Handoff is the only way that we should get to this point.
                selectedSessionID = handoffSessionID!
                handoffSessionID = nil
            } else {
                preconditionFailure("Unexpected segue sender, can't display Session.")
            }
            
            detailVC.sessionID = selectedSessionID
        case filterSegueIdentifier?:
            let navController = segue.destination as! UINavigationController
            let filterVC = navController.topViewController as! SessionFilterTableViewController
            filterVC.selectedType = filteredCategory
            filterVC.sessionTypes = { () -> [Session.Category] in
                let categoryKey = Session.Keys.category.rawValue
                let request = NSFetchRequest<NSDictionary>(entityName: Session.entityName)
                request.propertiesToFetch = [ categoryKey ]
                request.resultType = NSFetchRequestResultType.dictionaryResultType
                request.returnsDistinctResults = true
                
                do {
                    let results = try AppDelegate.persistentContainer.viewContext.fetch(request)
                    guard let stringly = results as? [[String:String]] else {
                        assertionFailure("Expected [[String:String]] result from fetch request.")
                        return []
                    }
                    
                    // This is probably very slow...
                    let allTypeProperties = stringly.map { dict -> String in return dict[categoryKey]! }
                    let types = allTypeProperties.flatMap { (types: String) -> [String] in
                        let separatedTypes = types.components(separatedBy: ", ")
                        return separatedTypes
                    }
                    
                    let unique = Set<String>(types)
                    let sorted = unique.sorted()
                    let categories = sorted.map { name in Session.Category(name: name) }
                    return categories
                } catch {
                    let error = error as NSError
                    NSLog("Error fetching session information: \(error)")
                }
                
                return []
                }()
        case searchSegueIdentifier?:
            let navController = segue.destination as! UINavigationController
            let searchVC = navController.topViewController as! SessionTableViewController
            searchVC.bookmarkedOnly = false
            
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SessionCollectionViewController.dismissSearchView))
            searchVC.defaultRightBarButtonItem = doneButton
        default:
            // Segues we don't know about are fine.
            break
        }
    }
    
    @IBAction func unwindAfterFiltering(_ segue: UIStoryboardSegue) {
        let filterVC = segue.source as! SessionFilterTableViewController
        filteredCategory = filterVC.selectedType
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func dismissSearchView() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections(in: collectionView)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dataSource.collectionView(collectionView, cellForItemAt: indexPath)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == StickyHeaderFlowLayout.StickyHeaderElementKind {
            // handle the sticky header ourselves
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dayControlHeaderReuseIdentifier, for: indexPath) as! SegmentedControlCollectionReusableView
            daySegmentedControl = view.segmentedControl
            
            return view
        } else {
            let view = dataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
            return view
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        dayScroller.willDisplayItemAtIndexPath(indexPath)
    }
    
    // MARK: - Scroll View Delegate
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        dayScroller.scrollViewDidEndScrollingAnimation()
    }
}

extension SessionCollectionViewController: SessionCollectionViewCellDelegate {
    func sessionCellBookmarkButtonTapped(_ cell: SessionCollectionViewCell) {
        do {
            try cell.viewModel?.toggleBookmarked()
        } catch {
            NSLog("Couldn't save after toggling session bookmarked status: \((error as NSError).localizedDescription)")
            let actionString = (cell.viewModel?.isBookmarked ?? false) ? "remove favorite" : "add favorite"
            let alert = UIAlertController(title: "Uh Oh", message: "Couldn't \(actionString). Sorry :(", preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Session Day Scroller

/**
Manages scrolling to days, and indicating the day of a displayed item, using a `UISegmentedControl`.
The `UIScrollViewDelegate` method `scrollViewDidEndScrollingAnimation` for `targetView` MUST be
forwarded to this class for the day indicator to update correctly.
*/
private class SessionDayScroller {
    fileprivate enum TargetView {
        case collectionView(UICollectionView)
        case tableView(UITableView)
    }
    
    fileprivate let fetchedResultsController: NSFetchedResultsController<Session>
    fileprivate let timeZone: TimeZone
    fileprivate let targetView: TargetView
    weak fileprivate var daySegmentedControl: UISegmentedControl? {
        didSet {
            // Set the names of the days on the day chooser segmented control
            guard let daysControl = daySegmentedControl else {
                return
            }
            
            let formatter = DateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"
            
            daysControl.removeAllSegments()
            for (idx, date) in days.enumerated() {
                let title = formatter.string(from: date)
                daysControl.insertSegment(withTitle: title, at: idx, animated: false)
            }
            
            daysControl.selectedSegmentIndex = 0
            daysControl.addTarget(self, action: #selector(SessionDayScroller.goToDay(_:)), for: UIControlEvents.valueChanged)
        }
    }
    
    /**
     Create an array of dates, set to midnight, of each day of the con.
     
     Hard-coded for Anime Detour.
     */
    fileprivate lazy var days: [Date] = {
        // Components for Friday at midnight
        var components = DateComponents()
        components.year = 2016
        components.month = 4
        components.day = 22
        components.hour = 0
        components.minute = 0
        components.timeZone = self.timeZone
        
        let calendar = NSCalendar.current
        let friday = calendar.date(from: components)!
        components.day = components.day.map { $0 + 1 }
        let saturday = calendar.date(from: components)!
        components.day = components.day.map { $0 + 1 }
        let sunday = calendar.date(from: components)!
        
        return [friday, saturday, sunday]
    }()
    
    /// `true` indicates that the view is currently scrolling to the first item on
    /// a particular day.
    fileprivate var scrollingToDay = false
    
    fileprivate var sectionOfLatestDisplayedItem: Int = 0 {
        didSet {
            guard sectionOfLatestDisplayedItem != oldValue else {
                return
            }
            
            guard let segmentedControl = daySegmentedControl else {
                return
            }
            
            let date = dateFor(sectionOfLatestDisplayedItem)
            if let idx = dayIndex(date) {
                segmentedControl.selectedSegmentIndex = idx
            }
        }
    }
    
    /**
     - parameter fetchedResultsController: The FRC using which the scroller will look up `Session`s and their starting times. Must return `Session`s and be sectioned on the key path `start`.
     - parameter daySegmentedControl: The control using which the day of the latest displayed `Session` will be indicated.
     */
    init(fetchedResultsController: NSFetchedResultsController<Session>, timeZone: TimeZone, targetView: TargetView) {
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        self.targetView = targetView
    }
    
    /**
     Finds the index of the date in `days` which is the same day as `date`.
     
     - returns: An index, or `nil` if no matching date was found.
     */
    fileprivate func dayIndex(_ date: Date) -> Int? {
        let dateAsInterval = date.timeIntervalSinceReferenceDate
        let fridayAsInterval = days[0].timeIntervalSinceReferenceDate
        let saturdayAsInterval = days[1].timeIntervalSinceReferenceDate
        let sundayAsInterval = days[2].timeIntervalSinceReferenceDate
        
        var dateIdx: Int?
        switch dateAsInterval {
        case fridayAsInterval ..< saturdayAsInterval:
            dateIdx = 0
        case saturdayAsInterval ..< sundayAsInterval:
            dateIdx = 1
        case sundayAsInterval ..< Date.distantFuture.timeIntervalSinceReferenceDate:
            dateIdx = 2
        default:
            break
        }
        
        return dateIdx
    }
    
    /**
     Find the index path of the first Session with a start time of `date` (or later),
     based on our `fetchedResultsController`'s current fetched sections.
     
     Find session with a start time of `date` or *before*, logic if `after` is `false`.
     */
    fileprivate func indexPathOfSection(_ date: Date, after: Bool = true) -> IndexPath? {
        let frc = fetchedResultsController
        
        let fallbackDate = Date.distantPast
        let test = { (info: NSFetchedResultsSectionInfo) -> Bool in
            let firstSession = info.objects?.first as? Session
            let sessionStart = firstSession?.start ?? fallbackDate
            
            // If `sessionStart.compare(date)` is `.OrderedDescending` or `.OrderedSame`,
            // i.e. it matches or comes after `date`, we found the Session we want.
            switch sessionStart.compare(date) {
            case .orderedDescending:
                return after ? true : false
            case .orderedSame:
                return true
            case .orderedAscending:
                return after ? false : true
            }
        }

        let index: Int?
        let sections = frc.sections
        if after {
            index = sections?.index(where: test)
        } else {
            // Use `Array(_)` since a reversed array doesn't use Int indices
            index = sections.map { Array($0.reversed()) }?.index(where: test)
        }
        
        return index.map { idx in IndexPath(item: 0, section: idx) }
    }
    
    /**
     The start date for `Session`s in a given section.
     */
    func dateFor(_ section: Int) -> Date {
        var indexPath: IndexPath
        switch targetView {
        case .collectionView:
            indexPath = IndexPath(item: 0, section: section)
        case .tableView:
            indexPath = IndexPath(row: 0, section: section)
        }
        
        let session = fetchedResultsController.object(at: indexPath)
        return session.start
    }
    
    /**
     Scroll to the first session at or after `date`. If `after` is `false`, scroll to the first session at or *before* `date`.
     
     - returns: `true` if scrolling was done, `false` if not.
     */
    func scroll(_ date: Date, after: Bool = true) -> Bool {
        guard let indexPath = indexPathOfSection(date, after: after) else {
            return false
        }
        
        scrollingToDay = true
        switch targetView {
        case let .collectionView(cv):
            if let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                let yCoordOfFirstView = flowLayout.yCoordinateForFirstItemInSection((indexPath as NSIndexPath).section)
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
        
        return true
    }
    
    func willDisplayItemAtIndexPath(_ indexPath: IndexPath) {
        guard !scrollingToDay else {
            return
        }
        
        sectionOfLatestDisplayedItem = (indexPath as NSIndexPath).section
        return
    }
    
    // MARK: - Scroll View Delegate
    
    func scrollViewDidEndScrollingAnimation() {
        // Delay un-setting `scrollingToDay` so we don't depend on ordering
        // relative to `willDisplayItemAtIndexPath(_:)`.
        DispatchQueue.main.async(execute: {
            self.scrollingToDay = false
        })
    }
    
    // MARK: - Received actions
    
    @IBAction @objc func goToDay(_ sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex
        let day = days[selectedIdx]
        let nineHoursInSeconds = 9 * 60 * 60 as TimeInterval
        let dayAt9AM = day.addingTimeInterval(nineHoursInSeconds)
        _ = scroll(dayAt9AM)
    }
}
