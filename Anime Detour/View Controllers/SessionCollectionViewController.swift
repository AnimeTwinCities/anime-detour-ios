//
//  SessionCollectionViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 2/7/15.
//  Copyright (c) 2015 Anime Detour. All rights reserved.
//

import UIKit
import CoreData

import AnimeDetourAPI

class SessionCollectionViewController: UICollectionViewController {
    private var imagesURLSession = NSURLSession.sharedSession()
    lazy private var refreshingTableViewController: UITableViewController = UITableViewController()
    lazy private var apiClient = AnimeDetourAPIClient.sharedInstance
    private var refreshing: Bool = false {
        didSet {
            if self.refreshing {
                self.refreshControl.beginRefreshing()
            } else {
                self.refreshControl.endRefreshing()
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
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: sessionsFetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "start", cacheName: nil)
        fetchedResultsController.delegate = self.fetchedResultsControllerDelegate
        return fetchedResultsController
    }()

    /// Type name for which the Session list will be filtered.
    /// Updating this property will update out `title`.
    /// Must not be changed before `fetchedResultsController` is created.
    private var filteredType: SelectedSessionType = .All {
        didSet {
            guard self.filteredType != oldValue else {
                return
            }

            self.navigationItem.title = self.filteredTitle(self.filteredType)

            self.fetchedResultsController.fetchRequest.predicate = self.completePredicate

            do {
                try self.fetchedResultsController.performFetch()
            } catch {
                let error = error as NSError
                let errorDesc = error.userInfo[NSLocalizedDescriptionKey] as? String ?? "Unknown error"
                print("Error performing Session fetch: %@", errorDesc)
            }

            self.collectionView!.reloadData()
        }
    }

    private var completePredicate: NSPredicate? {
        let bookmarkedPredicate: NSPredicate? = nil // needs to be rethought since the bookmarked status of a Session is not on the Session itself
        var predicates = [NSPredicate]()
        if let filterPredicate = self.filteredSessionsPredicate {
            predicates.append(filterPredicate)
        }
        if let bookmarkedPredicate = bookmarkedPredicate {
            predicates.append(bookmarkedPredicate)
        }
        let completePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return completePredicate
    }
    private var filteredSessionsPredicate: NSPredicate? {
        switch self.filteredType {
        case .All:
            return nil
        case let .Named(type):
            let begins = NSPredicate(format: "type BEGINSWITH %@", type)
            let contains = NSPredicate(format: "type CONTAINS %@", ", " + type + ",")
            let ends = NSPredicate(format: "type ENDSWITH %@", ", " + type)
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
            let sortDescriptors = [NSSortDescriptor(key: "start", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
            let sessionsFetchRequest = NSFetchRequest(entityName: Session.entityName)
            sessionsFetchRequest.sortDescriptors = sortDescriptors
            return sessionsFetchRequest
        }
    }

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
            self.dayScroller.daySegmentedControl = self.daySegmentedControl
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

        self.title = "Schedule"
        self.navigationItem.title = self.filteredTitle(self.filteredType)

        let collectionView = self.collectionView!

        self.addRefreshControl()

        collectionView.registerClass(SegmentedControlCollectionReusableView.self, forSupplementaryViewOfKind: StickyHeaderFlowLayout.StickyHeaderElementKind, withReuseIdentifier: self.dayControlHeaderReuseIdentifier)

        self.updateStickyHeaderLayoutTopOffset()
        self.updateScrollViewScrollerTopInsetForStickyHeader()

        self.dataSource.prepareCollectionView(self.collectionView!)
        self.fetchedResultsControllerDelegate.customizer = self.dataSource

        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let error = error as NSError
            NSLog("Error fetching sessions: %@", error)
        }

        self.setFlowLayoutCellSizes(collectionView, forLayoutSize: collectionView.frame.size)
        self.lastDisplayedTraitCollection = self.traitCollection
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let analytics = GAI.sharedInstance().defaultTracker {
            analytics.set(kGAIScreenName, value: AnalyticsConstants.Screen.Schedule)
            let dict = GAIDictionaryBuilder.createScreenView().build() as NSDictionary as! [NSObject : AnyObject]
            analytics.send(dict)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Possibly update cell sizes. Belongs in `viewDidAppear:`, as case the
        // trait collection is sometimes not up to date in `viewWillAppear:`.
        self.updateCellSizesIfNecessary()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let collectionView = self.collectionView!
        self.setFlowLayoutCellSizes(collectionView, forLayoutSize: size)

        self.traitCollectionAfterCurrentTransition = nil
        self.lastDisplayedTraitCollection = self.traitCollection
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        self.traitCollectionAfterCurrentTransition = newCollection
    }

    // MARK: - Collection view layout support
    
    private func updateCellSizesIfNecessary() {
        guard self.traitCollection != self.lastDisplayedTraitCollection else {
            return
        }

        let collectionView = self.collectionView!
        self.setFlowLayoutCellSizes(collectionView, forLayoutSize: collectionView.frame.size)
        self.lastDisplayedTraitCollection = self.traitCollection
    }

    /// Update the top offset for our layout, if it is a `StickyHeaderFlowLayout`.
    private func updateStickyHeaderLayoutTopOffset() {
        guard let stickyHeaderLayout = self.collectionViewLayout as? StickyHeaderFlowLayout else {
            return
        }
        
        // topLayoutGuide doesn't work for our purposes with a translucent navigation bar
        if let navBar = self.navigationController?.navigationBar where navBar.translucent {
            stickyHeaderLayout.headerTopOffset = navBar.frame.maxY
        } else {
            stickyHeaderLayout.headerTopOffset = self.topLayoutGuide.length
        }
    }
    
    /// Update the scroll view scroller to be below the sticky header
    private func updateScrollViewScrollerTopInsetForStickyHeader() {
        let collectionView = self.collectionView!
        let insets = collectionView.scrollIndicatorInsets
        var newInsets = insets
        if let stickyHeaderLayout = self.collectionViewLayout as? StickyHeaderFlowLayout {
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

        let traitCollection = self.traitCollectionAfterCurrentTransition ?? collectionView.traitCollection
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

    func filteredTitle(filteredSessionType: SelectedSessionType) -> String {
        let unfilteredTitle = "Sessions"
        switch self.filteredType {
        case .All:
            return unfilteredTitle
        case let .Named(type):
            return type
        }
    }

    // MARK: - Refreshing

    /// Add the refresh control to the collection view
    private func addRefreshControl() {
        let collectionView = self.collectionView!
        collectionView.addSubview(self.refreshControl)

        // Cheat and move the refresh control's bounds down, below the day selector header
        var headerHeight: CGFloat
        if let stickyHeaderLayout = self.collectionViewLayout as? StickyHeaderFlowLayout {
            headerHeight = stickyHeaderLayout.headerHeight
        } else {
            headerHeight = 50
        }
        var refreshBounds = self.refreshControl.bounds
        refreshBounds.offsetInPlace(dx: 0, dy: -headerHeight)
        self.refreshControl.bounds = refreshBounds
        
    }

    @objc private func refreshSessions(sender: AnyObject?) {
        guard !self.refreshing else {
            return
        }

        self.refreshing = true
        let moc = self.coreDataController.createManagedObjectContext(.PrivateQueueConcurrencyType)
        let dateFormatter = self.apiClient.dateFormatter

        self.apiClient.refreshSessions(moc, dateFormatter: dateFormatter) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshing = false
                return
            })
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let analytics: GAITracker? = GAI.sharedInstance().defaultTracker

        switch (segue.identifier) {
        case .Some(self.detailSegueIdentifier):
            let detailVC = segue.destinationViewController as! SessionViewController
            let selectedSession = (self.collectionView?.indexPathsForSelectedItems()?.first).map(self.dataSource.session)!
            detailVC.session = selectedSession

            let dict = GAIDictionaryBuilder.createEventWithCategory(AnalyticsConstants.Screen.Schedule, action: AnalyticsConstants.Actions.ViewDetails, label: selectedSession.name, value: nil).build() as NSDictionary as! [NSObject : AnyObject]
            analytics?.send(dict)
        case .Some(self.filterSegueIdentifier):
            let navController = segue.destinationViewController as! UINavigationController
            let filterVC = navController.topViewController as! SessionFilterTableViewController
            filterVC.selectedType = self.filteredType
            filterVC.sessionTypes = { () -> [String] in
                let typeKey = "type"
                let request = NSFetchRequest(entityName: Session.entityName)
                request.propertiesToFetch = [ typeKey ]
                request.resultType = NSFetchRequestResultType.DictionaryResultType
                request.returnsDistinctResults = true

                do {
                    let results = try self.managedObjectContext.executeFetchRequest(request)
                    guard let stringly = results as? [[String:String]] else {
                        assertionFailure("Expected [[String:String]] result from fetch request.")
                        return []
                    }
                    
                    // This is probably very slow...
                    let allTypeProperties = stringly.map { dict -> String in return dict[typeKey]! }
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
        case .Some(self.searchSegueIdentifier):
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
        self.filteredType = filterVC.selectedType

        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @objc private func dismissSearchView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dataSource.numberOfSectionsInCollectionView(collectionView)
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.dataSource.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
        return cell
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == StickyHeaderFlowLayout.StickyHeaderElementKind {
            // handle the sticky header ourselves
            let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: self.dayControlHeaderReuseIdentifier, forIndexPath: indexPath) as! SegmentedControlCollectionReusableView
            self.daySegmentedControl = view.segmentedControl

            return view
        } else {
            let view = self.dataSource.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
            return view
        }
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        self.dayScroller.willDisplayItemAtIndexPath(indexPath)
    }

    // MARK: - Scroll View Delegate

    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.dayScroller.scrollViewDidEndScrollingAnimation()
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
            guard let daysControl = self.daySegmentedControl else {
                return
            }
            
            let formatter = NSDateFormatter()
            // The full name of the day of the week, e.g. Monday
            formatter.dateFormat = "EEEE"
            
            daysControl.removeAllSegments()
            for (idx, date) in self.days.enumerate() {
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
        components.year = 2015
        components.month = 3
        components.day = 27
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
    private(set) var scrollingToDay = false

    private var sectionOfLatestDisplayedItem: Int = 0 {
        didSet {
            guard self.sectionOfLatestDisplayedItem != oldValue else {
                return
            }
            
            guard let segmentedControl = self.daySegmentedControl else {
                return
            }
            
            let date = self.date(self.sectionOfLatestDisplayedItem)
            if let idx = self.dayIndex(date) {
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
    Finds the index of the date in `self.days` which is the same day as `date`.

    - returns: An index, or `nil` if no matching date was found.
    */
    private func dayIndex(date: NSDate) -> Int? {
        let days = self.days
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
    sorted using the sort descriptors from out `fetchedResultsController`'s fetch request.
    */
    private func indexPathOfSection(date: NSDate) -> NSIndexPath? {
        let frc = self.fetchedResultsController
        let predicate = NSPredicate(format: "start >= %@", argumentArray: [date])
        let moc = self.fetchedResultsController.managedObjectContext
        let sortDescriptors = frc.fetchRequest.sortDescriptors
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(Session.entityName, inManagedObjectContext: moc)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors

        do {
            guard let results = try moc.executeFetchRequest(fetchRequest) as? [Session] else { return nil }
            guard let first = results.first else { return nil }
            return self.fetchedResultsController.indexPathForObject(first)
        } catch {
            let error = error as NSError
            NSLog("Error fetching first object with date %@: %@", date, error)
        }

        return nil
    }

    /**
    The start date for `Session`s in a given section.
    */
    func date(section: Int) -> NSDate {
        var indexPath: NSIndexPath
        switch self.targetView {
        case .CollectionView:
            indexPath = NSIndexPath(forItem: 0, inSection: section)
        case .TableView:
            indexPath = NSIndexPath(forRow: 0, inSection: section)
        }

        let session = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Session
        return session.start
    }

    /// Scroll to the first session for the day
    func scroll(date: NSDate) {
        guard let indexPath = self.indexPathOfSection(date) else {
            return
        }

        self.scrollingToDay = true
        switch self.targetView {
        case let .CollectionView(cv):
            if let flowLayout = cv.collectionViewLayout as? UICollectionViewFlowLayout {
                // Not animated, so we're not 'scrolling'
                self.scrollingToDay = false
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
        guard !self.scrollingToDay else {
            return
        }

        self.sectionOfLatestDisplayedItem = indexPath.section
        return
    }

    // MARK: - Scroll View Delegate

    func scrollViewDidEndScrollingAnimation() {
        self.scrollingToDay = false
    }

    // MARK: - Received actions

    @IBAction func goToDay(sender: UISegmentedControl) {
        let selectedIdx = sender.selectedSegmentIndex
        let day = self.days[selectedIdx]
        self.scroll(day)
    }
}
