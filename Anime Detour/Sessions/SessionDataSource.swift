//
//  SessionDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/22/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

/**
 Data source that provides SessionViewModels. Sectioned by the `start` time of the SessionViewModel.
 */
protocol SessionDataSource: DataSource {
    var sessionDataSourceDelegate: SessionDataSourceDelegate? { get set }
    
    func viewModel(at indexPath: IndexPath) -> SessionViewModel
    func indexPathOfSession(withSessionID sessionID: String) -> IndexPath?
    
    /**
     Get all of the sessions in the data source, up to some soft limit.
     More results than `limit` may be returned.
     */
    func allSessions(limit: Int) -> [SessionViewModel]
    
    /**
     The section of the first section which contains any sessions starting
     at or after `threshold`.
     */
    func firstSection(atOrAfter threshold: Date) -> Int?
    
    /**
     The section of the last section which contains any sessions starting
     before or at `threshold`.
     */
    func lastSection(atOrBefore threshold: Date) -> Int?
}

protocol FilterableSessionDataSource: class, SessionDataSource {
    /**
     A predicate against which all sessions will be checked, and only those that pass
     will ever be returned.
     */
    var filteringPredicate: ((SessionViewModel) -> Bool)? { get set }
}

enum SessionSectionInfo {
    case count(Int)
    case first(SessionViewModel)
}

extension SessionDataSource {
    func firstSection(atOrAfter threshold: Date) -> Int? {
        for sectionNumber in 0..<numberOfSections {
            let numberOfItemsInSection = numberOfItems(inSection: sectionNumber)
            guard numberOfItemsInSection > 0 else {
                continue
            }
            
            let firstIndexPath = IndexPath(item: 0, section: sectionNumber)
            let firstItem = viewModel(at: firstIndexPath)
            guard let start = firstItem.start, start >= threshold else {
                continue
            }
            
            return sectionNumber
        }
        
        return nil
    }
    
    func lastSection(atOrBefore threshold: Date) -> Int? {
        for sectionNumber in (0..<numberOfSections).reversed() {
            let numberOfItemsInSection = numberOfItems(inSection: sectionNumber)
            guard numberOfItemsInSection > 0 else {
                continue
            }
            
            let firstIndexPath = IndexPath(item: 0, section: sectionNumber)
            let firstItem = viewModel(at: firstIndexPath)
            guard let start = firstItem.start, start <= threshold else {
                continue
            }
            
            return sectionNumber
        }
        
        return nil
    }
    
    func daysForAllSessions() -> [Date] {
        var days: Set<Date> = []
        
        let calendar = Calendar.current
        
        for sectionNumber in 0..<numberOfSections {
            let numberOfItemsInSection = numberOfItems(inSection: sectionNumber)
            guard numberOfItemsInSection > 0 else {
                continue
            }
            
            let firstIndexPath = IndexPath(item: 0, section: sectionNumber)
            let firstItem = viewModel(at: firstIndexPath)
            guard let start = firstItem.start else {
                continue
            }
            
            let startAtMidnight = calendar.startOfDay(for: start)
            days.insert(startAtMidnight)
        }
        
        return days.sorted()
    }
    
    func sections(startingAfter threshold: Date) -> [Date: SessionSectionInfo] {
        var returnValues: [Date: SessionSectionInfo] = [:]
        
        guard let sectionAtOrAfter = firstSection(atOrAfter: threshold) else {
            return returnValues
        }
        
        for sectionNumber in sectionAtOrAfter..<numberOfSections {
            let numberOfItemsInSection = numberOfItems(inSection: sectionNumber)
            guard numberOfItemsInSection > 0 else {
                continue
            }
            
            let firstIndexPath = IndexPath(item: 0, section: sectionNumber)
            let firstItem = viewModel(at: firstIndexPath)
            guard let start = firstItem.start, start > threshold else {
                continue
            }
            
            let sectionInfo: SessionSectionInfo
            switch numberOfItemsInSection {
            case 1:
                sectionInfo = .first(firstItem)
            default:
                sectionInfo = .count(numberOfItemsInSection)
            }
            
            returnValues[start] = sectionInfo
        }
        
        return returnValues
    }
}

protocol SessionDataSourceDelegate: class {
    func sessionDataSourceDidUpdate()
}

final class SessionFixture: SessionDataSource, SessionStarsDataSource {
    static var items: [SessionViewModel] = [
        SessionViewModel(sessionID: "one", title: "First Session", description: "First Session Description", isStarred: false, category: SessionViewModel.Category(name: "android"), room: "auditorium", start: nil, end: nil, speakerIDs: [speakers[0].speakerID], tags: []),
        SessionViewModel(sessionID: "two", title: "Session Two", description: "Session Two Description", isStarred: true, category: SessionViewModel.Category(name: "design"), room: "classroom 1", start: nil, end: nil, speakerIDs: [], tags: []),
        SessionViewModel(sessionID: "three", title: "Session the Third", description: "Session the Third Description", isStarred: false, category: SessionViewModel.Category(name: ""), room: "lab", start: nil, end: nil, speakerIDs: [], tags: []),
        ]
    
    static var speakers: [SpeakerViewModel] { return SpeakerFixture.speakers }
    
    static let starredItems: [SessionViewModel] = items.filter { $0.isStarred }
    
    weak var sessionDataSourceDelegate: SessionDataSourceDelegate?
    weak var sessionStarsDataSourceDelegate: SessionStarsDataSourceDelegate?
    
    let numberOfSections: Int = 1
    
    func title(forSection section: Int) -> String? {
        return "Fixture Section Title"
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return SessionFixture.items.count
    }
    
    func viewModel(at indexPath: IndexPath) -> SessionViewModel {
        return SessionFixture.items[indexPath.item]
    }
    
    func indexPathOfSession(withSessionID sessionID: String) -> IndexPath? {
        let idx = SessionFixture.items.index(where: { return $0.sessionID == sessionID })
        let indexPath = idx.map { return IndexPath(item: $0, section: 0) }
        return indexPath
    }
    
    func allSessions(limit: Int) -> [SessionViewModel] {
        return SessionFixture.items
    }
    
    func isStarred(viewModel: SessionViewModel) -> Bool {
        let sessionIndexPath = indexPathOfSession(withSessionID: viewModel.sessionID)!
        let storedViewModel = SessionFixture.items[sessionIndexPath.item]
        return storedViewModel.isStarred
    }
    
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel {
        let sessionIndexPath = indexPathOfSession(withSessionID: viewModel.sessionID)!
        
        var updatedViewModel = SessionFixture.items[sessionIndexPath.item]
        updatedViewModel.isStarred = !updatedViewModel.isStarred
        
        SessionFixture.items[sessionIndexPath.item] = updatedViewModel
        
        return updatedViewModel
    }
    
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel {
        let sessionIndexPath = indexPathOfSession(withSessionID: viewModel.sessionID)!
        
        var updatedViewModel = SessionFixture.items[sessionIndexPath.item]
        updatedViewModel.isStarred = !updatedViewModel.isStarred
        
        SessionFixture.items[sessionIndexPath.item] = updatedViewModel
        
        return updatedViewModel
    }
}
