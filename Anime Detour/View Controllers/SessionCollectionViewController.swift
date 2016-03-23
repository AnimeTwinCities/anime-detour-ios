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
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy private var refreshingTableViewController: UITableViewController = UITableViewController()
    lazy private var apiClient = AnimeDetourAPIClient.sharedInstance
    private var refreshing: Bool = false {
        didSet {
            if refreshing {
                refreshControl.beginRefreshing()
            } else {
                refreshControl.endRefreshing()
            }
        }
    }
    
    /// Refresh control added to a dummy table view controller for the table view's management functionality
    lazy private var refreshControl: UIRefreshControl = { () -> UIRefreshControl in
        let control = UIRefreshControl()
        self.refreshingTableViewController.refreshControl = control
        
        control.addTarget(self, action: Selector("refreshSessions:"), forControlEvents: UIControlEvents.ValueChanged)
        
        return control
    }()
    
    // MARK: Core Data
    
    lazy private var coreDataController: CoreDataController = CoreDataController.sharedInstance
    lazy private var managedObjectContext: NSManagedObjectContext = self.coreDataController.managedObjectContext
    
    /// Fetched results controller over `Session`s.
    lazy private var fetchedResultsController: NSFetchedResultsController = {
        let sessionsFetchRequest = self.sessionsFetchRequest
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: Session.Keys.startTime.rawValue, cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()
    
    /// Category name for which the Session list will be filtered.
    /// Updating this property will update our `title`.
    /// Must not be changed before `fetchedResultsController` is created.
    private var filteredCategory: SelectedSessionCategory = .All {
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
    
    private var completePredicate: NSPredicate? {
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
    private var filteredSessionsPredicate: NSPredicate? {
        switch filteredCategory {
        case .All:
            return nil
        case let .Named(category):
            let begins = NSPredicate(format: "\(Session.Keys.category.rawValue) BEGINSWITH %@", category)
            let contains = NSPredicate(format: "\(Session.Keys.category.rawValue) CONTAINS %@", ", " + category + ",")
            let ends = NSPredicate(format: "\(Session.Keys.category.rawValue) ENDSWITH %@", ", " + category)
            let pred = NSCompoundPredicate(orPredicateWithSubpredicates: [begins, contains, ends])
            return pred
        }
    }
    lazy private var fetchedResultsControllerDelegate: CollectionViewFetchedResultsControllerDelegate = {
        let delegate = CollectionViewFetchedResultsControllerDelegate()
        delegate.collectionView = self.collectionView!
        return delegate
    }()
    
    /**
     Fetch request for all Sessions, sorted by start time then name. Creates a new fetch request on every access.
     */
    private var sessionsFetchRequest: NSFetchRequest {
        get {
            let sortDescriptors = [NSSortDescriptor(key: Session.Keys.startTime.rawValue, ascending: true), NSSortDescriptor(key: Session.Keys.name.rawValue, ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: Session.entityName)
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }
    
    // MARK: Handoff
    
    /**
    Session ID to display in a `SessionViewController` following a Handoff.
    Should be reset to `nil` after Handoff.
    */
    private var handoffSessionID: String?
    
    // MARK: Collection view
    
    /**
    Collection view data source that we call through to from our data
    source methods.
    */
    lazy private var dataSource: SessionDataSource = SessionDataSource(fetchedResultsController: self.fetchedResultsController, timeZone: self.timeZone, imagesURLSession: self.imagesURLSession)
    
    // MARK: Day indicator
    
    lazy private var dayScroller: SessionDayScroller = SessionDayScroller(fetchedResultsController: self.fetchedResultsController, timeZone: self.timeZone, targetView: .CollectionView(self.collectionView!))
    private var timeZone: NSTimeZone = NSTimeZone(name: "America/Chicago")! // hard-coded for Anime-Detour
    
    // MARK: Controls
    
    @IBOutlet var daySegmentedControl: UISegmentedControl? {
        didSet {
            dayScroller.daySegmentedControl = daySegmentedControl
        }
    }
    
    // MARK: Reuse identifiers
    
    private var dayControlHeaderReuseIdentifier: String = "dayControlHeaderReuseIdentifier"
    
    // MARK: Segue identifiers
    
    @IBInspectable var detailSegueIdentifier: String!
    @IBInspectable var filterSegueIdentifier: String!
    @IBInspectable var searchSegueIdentifier: String!
    
    // MARK: Collection view sizing
    
    private var traitCollectionAfterCurrentTransition: UITraitCollection?
    private var lastDisplayedTraitCollection: UITraitCollection!
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Schedule"
        navigationItem.title = filteredTitle(filteredCategory)
        
        let collectionView = self.collectionView!
        
        addRefreshControl()
        
        collectionView.registerClass(SegmentedControlCollectionReusableView.self, forSupplementaryViewOfKind: StickyHeaderFlowLayout.StickyHeaderElementKind, withReuseIdentifier: dayControlHeaderReuseIdentifier)
        
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Possibly update cell sizes. Belongs in `viewDidAppear:`, as case the
        // trait collection is sometimes not up to date in `viewWillAppear:`.
        updateCellSizesIfNecessary()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let collectionView = self.collectionView!
        setFlowLayoutCellSizes(collectionView, forLayoutSize: size)
        
        traitCollectionAfterCurrentTransition = nil
        lastDisplayedTraitCollection = traitCollection
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        traitCollectionAfterCurrentTransition = newCollection
    }
    
    // MARK: - UIResponder
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        guard let sessionID = activity.userInfo?[SessionViewController.sessionActivitySessionIDKey] as? String else {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: Session.entityName)
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Session.Keys.sessionID.rawValue, sessionID)
        let count = fetchedResultsController.managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        guard count == 1 else {
            // don't do anything, since we don't have the session for the ID that we received
            return
        }
        
        handoffSessionID = sessionID
        performSegueWithIdentifier(detailSegueIdentifier, sender: self)
    }
    
    // MARK: - Show next sessions that haven't yet started
    
    /// Scroll to the Session that started closest to, but not at or after, the current time.
    @IBAction private func showUpcomingSessions() {
        let now = NSDate()
        let fallbackDate = NSDate.distantPast()
        guard let sectionIndex = fetchedResultsController.indexOfFirstSectionPassing(test: { info in
            let firstSession = info.objects?.first as? Session
            let sessionStart = firstSession?.start ?? fallbackDate
            
            // Session starts before `now` if `sessionStart.compare(now)` is `.OrderedDescending`
            switch sessionStart.compare(now){
            case .OrderedDescending:
                return true
            case .OrderedAscending, .OrderedSame:
                return false
            }
        }) where sectionIndex > 0 else {
            return
        }
        
        let indexPath = NSIndexPath(forItem: 0, inSection: sectionIndex - 1)
        collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
    }
    
    // MARK: - Collection view layout support
    
    private func updateCellSizesIfNecessary() {
        guard traitCollection != lastDisplayedTraitCollection else {
            return
        }
        
        let collectionView = self.collectionView!
        setFlowLayoutCellSizes(collectionView, forLayoutSize: collectionView.frame.size)
        lastDisplayedTraitCollection = traitCollection
    }
    
    /// Update the top offset for our layout, if it is a `StickyHeaderFlowLayout`.
    private func updateStickyHeaderLayoutTopOffset() {
        guard let stickyHeaderLayout = collectionViewLayout as? StickyHeaderFlowLayout else {
            return
        }
        
        // topLayoutGuide doesn't work for our purposes with a translucent navigation bar
        if let navBar = navigationController?.navigationBar where navBar.translucent {
            stickyHeaderLayout.headerTopOffset = navBar.frame.maxY
        } else {
            stickyHeaderLayout.headerTopOffset = topLayoutGuide.length
        }
    }
    
    /// Update the scroll view scroller to be below the sticky header
    private func updateScrollViewScrollerTopInsetForStickyHeader() {
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
    private func setFlowLayoutCellSizes(collectionView: UICollectionView, forLayoutSize layoutSize: CGSize) {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let horizontalSpacing = layout.minimumInteritemSpacing
        
        let traitCollection = traitCollectionAfterCurrentTransition ?? collectionView.traitCollection
        let viewWidth = layoutSize.width
        
        var itemSize = layout.itemSize
        
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
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
    
    func filteredTitle(filteredSessionType: SelectedSessionCategory) -> String {
        let unfilteredTitle = "Sessions"
        switch filteredCategory {
        case .All:
            return unfilteredTitle
        case let .Named(type):
            return type
        }
    }
    
    // MARK: - Refreshing
    
    /**
     Add the refresh control to the collection view.
     
     - Note: Also sets `alwaysBounceVertical` on the collection view, so it may be refreshed event
     when empty.
     */
    private func addRefreshControl() {
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
        refreshBounds.offsetInPlace(dx: 0, dy: -headerHeight)
        refreshControl.bounds = refreshBounds
    }
    
    @objc private func refreshSessions(sender: AnyObject?) {
        guard !refreshing else {
            return
        }
        
        refreshing = true
        let moc = coreDataController.createManagedObjectContext(.PrivateQueueConcurrencyType)
        
        apiClient.refreshSessions(moc) {
            dispatch_async(dispatch_get_main_queue()) {
                self.refreshing = false
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier {
        case detailSegueIdentifier?:
            let detailVC = segue.destinationViewController as! SessionViewController
            let indexPath: NSIndexPath?
            let selectedSessionID: String
            if let cell = sender as? UICollectionViewCell {
                indexPath = collectionView?.indexPathForCell(cell)
                let selectedSession = indexPath.map(dataSource.sessionAt)!
                selectedSessionID = selectedSession.sessionID
            } else if sender === self {
                // Handoff is the only way that we should get to this point.
                selectedSessionID = handoffSessionID!
                handoffSessionID = nil
            } else {
                preconditionFailure("Unexpected segue sender, can't display Session.")
            }
            
            detailVC.sessionID = selectedSessionID
        case filterSegueIdentifier?:
            let navController = segue.destinationViewController as! UINavigationController
            let filterVC = navController.topViewController as! SessionFilterTableViewController
            filterVC.selectedType = filteredCategory
            filterVC.sessionTypes = { () -> [String] in
                let categoryKey = Session.Keys.category.rawValue
                let request = NSFetchRequest(entityName: Session.entityName)
                request.propertiesToFetch = [ categoryKey ]
                request.resultType = NSFetchRequestResultType.DictionaryResultType
                request.returnsDistinctResults = true
                
                do {
                    let results = try managedObjectContext.executeFetchRequest(request)
                    guard let stringly = results as? [[String:String]] else {
                        assertionFailure("Expected [[String:String]] result from fetch request.")
                        return []
                    }
                    
                    // This is probably very slow...
                    let allTypeProperties = stringly.map { dict -> String in return dict[categoryKey]! }
                    let types = allTypeProperties.flatMap { (types: String) -> [String] in
                        let separatedTypes = types.componentsSeparatedByString(", ")
                        return separatedTypes
                    }
                    
                    let unique = Set<String>(types)
                    return unique.sort()
                } catch {
                    let error = error as NSError
                    NSLog("Error fetching session information: \(error)")
                }
                
                return []
                }()
        case searchSegueIdentifier?:
            let navController = segue.destinationViewController as! UINavigationController
            let searchVC = navController.topViewController as! SessionTableViewController
            searchVC.bookmarkedOnly = false
            
            let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("dismissSearchView"))
            searchVC.defaultRightBarButtonItem = doneButton
        default:
            // Segues we don't know about are fine.
            break
        }
    }
    
    @IBAction func unwindAfterFiltering(segue: UIStoryboardSegue) {
        let filterVC = segue.sourceViewController as! SessionFilterTableViewController
        filteredCategory = filterVC.selectedType
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func dismissSearchView() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSectionsInCollectionView(collectionView)
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = dataSource.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == StickyHeaderFlowLayout.StickyHeaderElementKind {
            // handle the sticky header ourselves
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: dayControlHeaderReuseIdentifier, forIndexPath: indexPath) as! SegmentedControlCollectionReusableView
            daySegmentedControl = view.segmentedControl
            
            return view
        } else {
            let view = dataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
            return view
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        dayScroller.willDisplayItemAtIndexPath(indexPath)
    }
    
    // MARK: - Scroll View Delegate
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        dayScroller.scrollViewDidEndScrollingAnimation()
    }
}

private extension NSFetchedResultsController {
    /**
     Find the first section that passes `test`.
     
     As all sections should contain at least one object, this can be used to find the
     first object whose value for the `sectionNameKeyPath` passes `test`.
     */
    func indexOfFirstSectionPassing(@noescape test test: (sectionInfo: NSFetchedResultsSectionInfo) -> Bool) -> Int? {
        guard let (idx, _) = sections?.enumerate().filter({ _, info in
            return test(sectionInfo: info)
        }).first else {
            return nil
        }
        
        return idx
    }
}

// MARK: - Session Day Scroller

/**
Manages scrolling to days, and indicating the day of a displayed item, using a `UISegmentedControl`.
The `UIScrollViewDelegate` method `scrollViewDidEndScrollingAnimation` for `targetView` MUST be
forwarded to this class for the day indicator to update correctly.
*/
private class SessionDayScroller {
    private enum TargetView {
        case CollectionView(UICollectionView)
        case TableView(UITableView)
    }
    
    private let fetchedResultsController: NSFetchedResultsController
    private let timeZone: NSTimeZone
    private let targetView: TargetView
    weak private var daySegmentedControl: UISegmentedControl? {
        didSet {
            // Set the names of the days on the day chooser segmented control
            guard let daysControl = daySegmentedControl else {
                return
            }
            
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"
            
            daysControl.removeAllSegments()
            for (idx, date) in days.enumerate() {
                let title = formatter.stringFromDate(date)
                daysControl.insertSegmentWithTitle(title, atIndex: idx, animated: false)
            }
            
            daysControl.selectedSegmentIndex = 0
            daysControl.addTarget(self, action: Selector("goToDay:"), forControlEvents: UIControlEvents.ValueChanged)
        }
    }
    
    /**
     Create an array of dates, set to midnight, of each day of the con.
     
     Hard-coded for Anime Detour.
     */
    private lazy var days: [NSDate] = {
        // Components for Friday at midnight
        let components = NSDateComponents()
        components.year = 2016
        components.month = 4
        components.day = 22
        components.hour = 0
        components.minute = 0
        components.timeZone = self.timeZone
        
        let calendar = NSCalendar.currentCalendar()
        let friday = calendar.dateFromComponents(components)!
        components.day += 1
        let saturday = calendar.dateFromComponents(components)!
        components.day += 1
        let sunday = calendar.dateFromComponents(components)!
        
        return [friday, saturday, sunday]
    }()
    
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
    init(fetchedResultsController: NSFetchedResultsController, timeZone: NSTimeZone, targetView: TargetView) {
        self.fetchedResultsController = fetchedResultsController
        self.timeZone = timeZone
        self.targetView = targetView
    }
    
    /**
     Finds the index of the date in `days` which is the same day as `date`.
     
     - returns: An index, or `nil` if no matching date was found.
     */
    private func dayIndex(date: NSDate) -> Int? {
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
        case sundayAsInterval ..< NSDate.distantFuture().timeIntervalSinceReferenceDate:
            dateIdx = 2
        default:
            break
        }
        
        return dateIdx
    }
    
    /**
     Find the index path of the first Session with a start time of `date` (or later),
     based on our `fetchedResultsController`'s current fetched sections.
     */
    private func indexPathOfSection(date: NSDate) -> NSIndexPath? {
        let frc = fetchedResultsController
        
        let fallbackDate = NSDate.distantPast()
        return frc.indexOfFirstSectionPassing { info in
            let firstSession = info.objects?.first as? Session
            let sessionStart = firstSession?.start ?? fallbackDate
            
            // If `sessionStart.compare(date)` is `.OrderedDescending` or `.OrderedSame`,
            // i.e. it matches or comes after `date`, we found the Session we want.
            switch sessionStart.compare(date) {
            case .OrderedDescending, .OrderedSame:
                return true
            case .OrderedAscending:
                return false
            }
        }.map { idx in return NSIndexPath(forItem: 0, inSection: idx) }
    }
    
    /**
     The start date for `Session`s in a given section.
     */
    func dateFor(section: Int) -> NSDate {
        var indexPath: NSIndexPath
        switch targetView {
        case .CollectionView:
            indexPath = NSIndexPath(forItem: 0, inSection: section)
        case .TableView:
            indexPath = NSIndexPath(forRow: 0, inSection: section)
        }
        
        let session = fetchedResultsController.objectAtIndexPath(indexPath) as! Session
        return session.start
    }
    
    /// Scroll to the first session for the day
    func scroll(date: NSDate) {
        guard let indexPath = indexPathOfSection(date) else {
            return
        }
        
        scrollingToDay = true
        switch targetView {
        case let .CollectionView(cv):
            if let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                // Not animated, so we're not 'scrolling'
                scrollingToDay = false
                let yCoordOfFirstView = flowLayout.yCoordinateForFirstItemInSection(indexPath.section)
                var offset = cv.contentOffset
                offset.y = yCoordOfFirstView
                cv.contentOffset = offset
            } else {
                cv.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
            }
        case let .TableView(tv):
            tv.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
    func willDisplayItemAtIndexPath(indexPath: NSIndexPath) {
        guard !scrollingToDay else {
            return
        }
        
        sectionOfLatestDisplayedItem = indexPath.section
        return
    }
    
    // MARK: - Scroll View Delegate
    
    func scrollViewDidEndScrollingAnimation() {
        scrollingToDay = false
    }
    
    // MARK: - Received actions
    
    @IBAction func goToDay(sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex
        let day = days[selectedIdx]
        scroll(day)
    }
}
