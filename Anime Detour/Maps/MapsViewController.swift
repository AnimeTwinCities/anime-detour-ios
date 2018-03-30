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
 Show multiple separate PDFs in a page view controller.
 */
class MapsViewController: UIViewController {
    fileprivate let pageViewController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal, options: nil)
    var mapFileNames = ["Hyatt-AllFloors"] {
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
    
    fileprivate var activeMapIndex: Int = 0
    fileprivate var mapViewControllers: [SingleMapViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        let pageView = pageViewController.view!
        view.dev_addSubview(pageView)
        addChildViewController(pageViewController)
        pageView.dev_constrainToSuperEdges()

        mapViewControllers = makeMapViewControllers()
        pageViewController.setViewControllers([mapViewControllers.first!], direction: .forward, animated: false, completion: nil)
    }
    
    private func makeMapViewControllers() -> [SingleMapViewController] {
        return mapPaths.map(SingleMapViewController.init(mapFilePath:))
    }

    private func showMap(atIndex index: Int) {
        let isForward: Bool = index > activeMapIndex
        let direction = isForward ? UIPageViewControllerNavigationDirection.forward : .reverse
        pageViewController.setViewControllers([mapViewControllers[activeMapIndex]], direction: direction, animated: true, completion: nil)
        activeMapIndex = index
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
        let currentViewControllers = pageViewController.viewControllers
        let firstVC = currentViewControllers?.first as? SingleMapViewController
        let idx = firstVC.flatMap(mapViewControllers.index(of:))
        activeMapIndex = idx ?? 0
    }
}
