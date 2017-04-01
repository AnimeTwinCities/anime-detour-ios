//
//  CombinedSessionDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/26/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

/**
 A pass-through Session data source that persists Session starred status.
 Only really implements `FilterableSessionDataSource` if `dataSource` implements it.
 
 It is recommended that instances of this class be the `sessionDataSourceDelegate`s
 of their `dataSource` property.
 */
class CombinedSessionDataSource: SessionDataSource, SessionStarsDataSource, FilterableSessionDataSource {
    /// The data source that we will get our sessions from.
    let dataSource: SessionDataSource
    /// The data source that we will get our session starred statuses from.
    let starsDataSource: SessionStarsDataSource
    
    weak var sessionDataSourceDelegate: SessionDataSourceDelegate?
    weak var sessionStarsDataSourceDelegate: SessionStarsDataSourceDelegate?
    
    var filteringPredicate: ((SessionViewModel) -> Bool)? {
        didSet {
            if let filterable = dataSource as? FilterableSessionDataSource {
                filterable.filteringPredicate = filteringPredicate
            }
        }
    }
    
    /**
     `false` by default. Changing this value requires any consumers to reload all data
     obtained from this class.
     */
    var shouldIncludeOnlyStarred: Bool = false
    
    var numberOfSections: Int {
        return ourSectionsToDataSourceSections.count
    }
    
    private var ourSectionsToDataSourceSections: [Int:Int] {
        let dataSourceSections = dataSource.numberOfSections
        
        var numberOfSections = 0
        var sectionsToSections: [Int:Int] = [:]
        
        guard shouldIncludeOnlyStarred else {
            for idx in 0..<dataSourceSections {
                sectionsToSections[idx] = idx
            }
            
            return sectionsToSections
        }
        
        for section in 0..<dataSourceSections {
            for idx in 0..<dataSource.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: idx, section: section)
                let session = dataSource.viewModel(at: indexPath)
                
                if isStarred(viewModel: session) {
                    sectionsToSections[numberOfSections] = section
                    numberOfSections += 1
                    break
                }
            }
        }
        
        return sectionsToSections
    }
    
    init(dataSource: SessionDataSource, starsDataSource: SessionStarsDataSource) {
        self.dataSource = dataSource
        self.starsDataSource = starsDataSource
    }
    
    func dataSourceIndexPathForItem(at indexPath: IndexPath) -> IndexPath {
        guard shouldIncludeOnlyStarred else {
            return indexPath
        }
        
        let translatedSection = ourSectionsToDataSourceSections[indexPath.section]!
        let ourIndex = indexPath.item
        
        var dataSourceStarredSoFar = 0
        for idx in 0..<dataSource.numberOfItems(inSection: translatedSection) {
            let dataSourceIndexPath = IndexPath(item: idx, section: translatedSection)
            let session = dataSource.viewModel(at: dataSourceIndexPath)
            let sessionStarred = isStarred(viewModel: session)
            
            if sessionStarred {
                dataSourceStarredSoFar += 1
                if ourIndex == dataSourceStarredSoFar - 1 {
                    return dataSourceIndexPath
                }
            } else {
                continue
            }
        }
        
        assertionFailure("Couldn't find data source index path for an item")
        return IndexPath(item: 0, section: 0)
    }
    
    func indexPathForItem(atDataSourceIndexPath dataSourceIndexPath: IndexPath) -> IndexPath? {
        guard shouldIncludeOnlyStarred else {
            return dataSourceIndexPath
        }
        
        let dataSourceItem = dataSourceIndexPath.item
        let dataSourceSection = dataSourceIndexPath.section
        
        var starredSoFar = 0
        for idx in 0...dataSourceItem {
            let indexPath = IndexPath(item: idx, section: dataSourceSection)
            let session = dataSource.viewModel(at: indexPath)
            let sessionStarred = isStarred(viewModel: session)
            
            if sessionStarred {
                starredSoFar += 1
            }
        }
        
        if let ourSection = ourSectionsToDataSourceSections.first(where: { (key, value) -> Bool in
            return value == dataSourceSection
        })?.key {
            let foundIndexPath = IndexPath(item: starredSoFar - 1, section: ourSection)
            return foundIndexPath
        } else {
            return nil
        }
    }
    
    // MARK: - SessionDataSource
    
    func viewModel(at indexPath: IndexPath) -> SessionViewModel {
        let dataSourceIndexPath = dataSourceIndexPathForItem(at: indexPath)
        var vm = dataSource.viewModel(at: dataSourceIndexPath)
        vm.isStarred = isStarred(viewModel: vm)
        return vm
    }
    
    func indexPathOfSession(withSessionID sessionID: String) -> IndexPath? {
        guard let dataSourceIndexPath = dataSource.indexPathOfSession(withSessionID: sessionID) else {
            return nil
        }
        
        let indexPath = indexPathForItem(atDataSourceIndexPath: dataSourceIndexPath)
        return indexPath
    }
    
    // MARK: - DataSource
    
    func numberOfItems(inSection section: Int) -> Int {
        guard shouldIncludeOnlyStarred else {
            return dataSource.numberOfItems(inSection: section)
        }
        
        guard let translatedSection = ourSectionsToDataSourceSections[section] else {
            return 0
        }
        
        var starredSoFar = 0
        for idx in 0..<dataSource.numberOfItems(inSection: translatedSection) {
            let indexPath = IndexPath(item: idx, section: translatedSection)
            let session = dataSource.viewModel(at: indexPath)
            let sessionStarred = isStarred(viewModel: session)
            if sessionStarred {
                starredSoFar += 1
            }
        }

        return starredSoFar
    }
    
    func title(forSection section: Int) -> String? {
        guard let translatedSection = ourSectionsToDataSourceSections[section] else {
            return nil
        }
        return dataSource.title(forSection: translatedSection)
    }
    
    // MARK: - SessionStarsDataSource
    
    func isStarred(viewModel: SessionViewModel) -> Bool {
        // Ignore the `viewModel`s `isStarred`, checking our data store instead.
        return starsDataSource.isStarred(viewModel: viewModel)
    }
    
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return starsDataSource.starSession(for: viewModel)
    }
    
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return starsDataSource.unstarSession(for: viewModel)
    }
}

extension CombinedSessionDataSource: SessionDataSourceDelegate, SessionStarsDataSourceDelegate {
    func sessionDataSourceDidUpdate() {
        // do something here?
        sessionDataSourceDelegate?.sessionDataSourceDidUpdate()
    }
    
    internal func sessionStarsDidUpdate(dataSource: SessionStarsDataSource) {
        // do something here too?
        for section in 0..<self.dataSource.numberOfSections {
            for idx in 0..<self.dataSource.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: idx, section: section)
                var session = self.dataSource.viewModel(at: indexPath)
                session.isStarred = dataSource.isStarred(viewModel: session)
            }
        }
        sessionStarsDataSourceDelegate?.sessionStarsDidUpdate(dataSource: dataSource)
    }
}
