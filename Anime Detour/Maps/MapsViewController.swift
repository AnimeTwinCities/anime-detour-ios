//
//  MapsViewController.swift
//  Anime Detour
//
//  Created by Brendon Justin on 10/19/14.
//  Copyright (c) 2014 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import PDFKit

/**
 Show multiple separate PDFs with a segmented control to choose which one is currently displayed.
 */
class MapsViewController: UIViewController {
    @IBOutlet var pageSegmentedControl: UISegmentedControl!
    
    fileprivate let pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal, options: nil)
    var mapFileNames = ["DoubleTree_Floor1", "DoubleTree_Floor2", "DoubleTree_Floor22"] {
        didSet {
            guard isViewLoaded else {
                return
            }
            
            mapViewControllers = makeMapViewControllers()
            pageViewController.setViewControllers([mapViewControllers.first!], direction: .forward, animated: false, completion: nil)
        }
    }
    
    fileprivate var mapPaths: [String] {
        let mainBundle = Bundle.main
        let mapPaths = self.mapFileNames.map { (filename: String) -> String in
            return mainBundle.path(forResource: filename, ofType: "pdf")!
        }

        return mapPaths
    }
    
    fileprivate var activeMapIndex: Int = 0 {
        didSet {
            let isForward: Bool = activeMapIndex > oldValue
            let direction = isForward ? UIPageViewControllerNavigationDirection.forward : .reverse
            pageViewController.setViewControllers([mapViewControllers[activeMapIndex]], direction: direction, animated: true, completion: nil)
        }
    }
    fileprivate var mapViewControllers: [SingleMapViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageSegmentedControl.setTitle(NSLocalizedString("1st Floor", comment: "Map floor one"), forSegmentAt: 0)
        pageSegmentedControl.setTitle(NSLocalizedString("2nd Floor", comment: "Map floor two"), forSegmentAt: 1)
        pageSegmentedControl.setTitle(NSLocalizedString("22nd Floor", comment: "Map floor 22"), forSegmentAt: 2)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        let pageView = pageViewController.view!
        view.dev_addSubview(pageView)
        addChildViewController(pageViewController)
        
        let constraints: [NSLayoutConstraint] = [
            pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageView.topAnchor.constraint(equalTo: view.topAnchor),
            pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        NSLayoutConstraint.activate(constraints)
        
        mapViewControllers = makeMapViewControllers()
        pageViewController.setViewControllers([mapViewControllers.first!], direction: .forward, animated: false, completion: nil)
    }
    
    private func makeMapViewControllers() -> [SingleMapViewController] {
        return mapPaths.map(SingleMapViewController.init(mapFilePath:))
    }
    
    // MARK: - Segmented Control

    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl?) {
        activeMapIndex = sender?.selectedSegmentIndex ?? 0
    }
}

extension MapsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let mapVC = viewController as? SingleMapViewController, let idx = mapViewControllers.index(of: mapVC), idx > mapViewControllers.startIndex else {
            return nil
        }
        
        return mapViewControllers[idx - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let mapVC = viewController as? SingleMapViewController, let idx = mapViewControllers.index(of: mapVC), idx + 1 < mapViewControllers.endIndex else {
            return nil
        }
        
        return mapViewControllers[idx + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentViewControllers = pageViewController.viewControllers, let firstVC = currentViewControllers.first as? SingleMapViewController, let idx = mapViewControllers.index(of: firstVC) else {
            return
        }
        
        pageSegmentedControl.selectedSegmentIndex = idx
    }
}
