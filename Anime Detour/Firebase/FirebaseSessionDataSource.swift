//
//  FirebaseSessionDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/21/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import UIKit
import FirebaseDatabase

/**
 Provides sessions from Firebase. Does not ever change session starred status.
 
 The `star`/`unstar` methods do nothing.
 */
class FirebaseSessionDataSource: SessionDataSource, FilterableSessionDataSource {
    private let databaseReference: FIRDatabaseReference
    private let firebaseDateFormatter: DateFormatter
    private let sectionHeaderDateFormatter: DateFormatter
    
    weak var sessionDataSourceDelegate: SessionDataSourceDelegate?
    
    var filteringPredicates: Set<FilterableSessionDataSourcePredicate> = [] {
        didSet {
            if oldValue == [], filteringPredicates == [] {
                return
            }
            
            updateFilteredSessions(oldFilteringPredicates: oldValue)
            sessionDataSourceDelegate?.sessionDataSourceDidUpdate(filtering: !filteringPredicates.isEmpty)
        }
    }
    
    var numberOfSections: Int {
        return filteredSessionsByStart.keys.count
    }
    
    fileprivate var sessions: [SessionViewModel] = [] {
        didSet {
            self.sessionsByStart = generateSessionsByStart()
        }
    }
    
    fileprivate var filteredSessionsByStart: [Date:[SessionViewModel]] = [:]
    
    /// `workingSessions` grouped by each session's startTime
    fileprivate var sessionsByStart: [Date:[SessionViewModel]] = [:] {
        didSet {
            updateFilteredSessions()
        }
    }
    
    init(databaseReference: FIRDatabaseReference = FIRDatabase.database().reference(), firebaseDateFormatter: DateFormatter, sectionHeaderDateFormatter: DateFormatter) {
        self.databaseReference = databaseReference
        self.firebaseDateFormatter = firebaseDateFormatter
        self.sectionHeaderDateFormatter = sectionHeaderDateFormatter
        
        databaseReference.child("events").child("ad-2017").observe(.value) { [weak self] (snapshot: FIRDataSnapshot) in
            guard let dict = snapshot.value as? [String:Any], let _ = self else {
                return
            }
            
            DispatchQueue.global(qos: .default).async {
                var newSessions: [SessionViewModel] = []
                
                for (key, value) in dict {
                    if let dictValue = value as? [String:Any],
                        let viewModel = SessionViewModel(id: key, firebaseData: dictValue, firebaseDateFormatter: firebaseDateFormatter) {
                        newSessions.append(viewModel)
                    }
                }
                
                let sortedSessions = newSessions.sorted(by: { (vmOne, vmTwo) -> Bool in
                    return vmOne.sessionID < vmTwo.sessionID
                })
                
                DispatchQueue.main.async {
                    self?.sessions = sortedSessions
                    self?.sessionDataSourceDelegate?.sessionDataSourceDidUpdate(filtering: false)
                }
            }
        }
    }
    
    private func date(forSection section: Int) -> Date {
        let dateForSection = filteredSessionsByStart.keys.sorted()[section]
        return dateForSection
    }
    
    func title(forSection section: Int) -> String? {
        if case let dateForSection = date(forSection: section), dateForSection != .distantPast {
            let title = sectionHeaderDateFormatter.string(from: dateForSection)
            return title
        } else {
            return NSLocalizedString("Start time not listed", comment: "Section header for Sessions without a start time")
        }
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return filteredSessionsByStart[date(forSection: section)]!.count
    }
    
    func viewModel(at indexPath: IndexPath) -> SessionViewModel {
        let vm = filteredSessionsByStart[date(forSection: indexPath.section)]![indexPath.item]
        return vm
    }
    
    func indexPathOfSession(withSessionID sessionID: String) -> IndexPath? {
        var indexPath: IndexPath?
        
        for section in 0..<numberOfSections {
            let date = self.date(forSection: section)
            let sessionsForStart = filteredSessionsByStart[date]!
            
            guard let foundSessionIdx = sessionsForStart.index(where: { vm in vm.sessionID == sessionID }) else {
                continue
            }
            
            indexPath = IndexPath(item: foundSessionIdx, section: section)
        }
        
        return indexPath
    }
    
    func allSessions(limit: Int) -> [SessionViewModel] {
        guard limit > 0 else {
            return []
        }
        
        var returnSessions: [SessionViewModel] = []
        
        for (_, sessions) in sessionsByStart {
            returnSessions.append(contentsOf: sessions)
            
            guard returnSessions.count > limit else {
                break
            }
        }
        
        return returnSessions
    }
    
    func firstSection(atOrAfter threshold: Date) -> Int? {
        let sectionAndSessionDate = filteredSessionsByStart.keys.sorted().enumerated().first {
            return $0.1 >= threshold
        }
        
        if let sectionAndSessionDate = sectionAndSessionDate {
            return sectionAndSessionDate.0
        }
        
        return nil
    }
    
    func lastSection(atOrBefore threshold: Date) -> Int? {
        let sectionAndSessionDate = filteredSessionsByStart.keys.sorted().reversed().enumerated().first {
            return $0.1 <= threshold
        }
        
        if let sectionAndSessionDate = sectionAndSessionDate {
            return sectionAndSessionDate.0
        }
        
        return nil
    }
    
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return viewModel
    }
    
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return viewModel
    }
    
}

private extension FirebaseSessionDataSource {
    func generateSessionsByStart() -> [Date:[SessionViewModel]] {
        var collected: [Date:[SessionViewModel]] = [:]
        for session in sessions {
            let startTime = session.start ?? .distantPast
            
            collected[startTime, defaulting: []].append(session)
        }
        
        return collected
    }
    
    func updateFilteredSessions(oldFilteringPredicates: Set<FilterableSessionDataSourcePredicate>? = nil) {
        guard !filteringPredicates.isEmpty else {
            filteredSessionsByStart = sessionsByStart
            return
        }
        
        let filterUsingBaseSessions: ([Date:[SessionViewModel]]) -> Void = { baseSessions in
            var filtered: [Date:[SessionViewModel]] = [:]
            
            for (date, sessionsForDate) in baseSessions {
                let passingSessions = sessionsForDate.filter { session in
                    for predicate in self.filteringPredicates {
                        switch predicate {
                        case .nameContains(let namePart):
                            let containsPart = session.title.localizedCaseInsensitiveContains(namePart)
                            if !containsPart {
                                return false
                            }
                        }
                    }
                    
                    return true
                }
                
                if !passingSessions.isEmpty {
                    filtered[date] = passingSessions
                }
            }
            
            self.filteredSessionsByStart = filtered
        }
        
        guard let oldFilteringPredicates = oldFilteringPredicates else {
            filterUsingBaseSessions(sessionsByStart)
            return
        }
        
        var newPredicatesIncludeOldAsPrefix = true
        
        for oldPredicate in oldFilteringPredicates {
            var isPrefixOfANewPredicate = false
            
            for newPredicate in filteringPredicates {
                switch (oldPredicate, newPredicate) {
                case (.nameContains(let oldNameContains), .nameContains(let newNameContains)):
                    if newNameContains.hasPrefix(oldNameContains) {
                        isPrefixOfANewPredicate = true
                        break
                    }
                }
            }
            
            if !isPrefixOfANewPredicate {
                newPredicatesIncludeOldAsPrefix = false
                break
            }
        }
        
        if !newPredicatesIncludeOldAsPrefix {
            filterUsingBaseSessions(sessionsByStart)
        } else {
            filterUsingBaseSessions(self.filteredSessionsByStart)
        }
    }
}

extension SessionViewModel {
    init?(id: String, firebaseData dict: [String:Any], firebaseDateFormatter: DateFormatter) {
        guard let title = dict["name"] as? String else {
            return nil
        }
        
        let description = dict["description"] as? String
        let categoryString = dict["category"] as? String
        let category = categoryString.map { SessionViewModel.Category(name: $0) }
        let room = dict["room"] as? String
        
        // start/end times
        let startString = dict["start"] as? String ?? dict["startTime"] as? String
        let start: Date? = startString.flatMap { $0.nonEmptyString }.flatMap(firebaseDateFormatter.date)
        let endString = dict["end"] as? String ?? dict["endTime"] as? String
        let end: Date? = endString.flatMap { $0.nonEmptyString }.flatMap(firebaseDateFormatter.date)
        
        let tags = dict["tags"] as? [String]
        
        let speakerIDs = dict["speakers"] as? [String]
        
        let isStarred = false
        
        self.init(sessionID: id, title: title, description: description, isStarred: isStarred, category: category, room: room, start: start, end: end, speakerIDs: speakerIDs ?? [], tags: tags ?? [])
    }
}

private extension String {
    var nonEmptyString: String? {
        if self == "" {
            return nil
        } else {
            return self
        }
    }
}
