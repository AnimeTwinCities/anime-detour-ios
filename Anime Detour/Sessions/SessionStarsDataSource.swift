//
//  SessionStarsDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 12/26/16.
//  Copyright © 2016 GDGConferenceApp. All rights reserved.
//

import Foundation

// Not a table/collection view-style data source, so don't conform to `DataSource`.
protocol SessionStarsDataSource {
    var sessionStarsDataSourceDelegate: SessionStarsDataSourceDelegate? { get set }
    
    func isStarred(viewModel: SessionViewModel) -> Bool
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel
}

protocol SessionStarsDataSourceDelegate: class {
    func sessionStarsDidUpdate(dataSource: SessionStarsDataSource)
}

final class MultiSessionStarsDataSourceDelegate: SessionStarsDataSourceDelegate {
    var broadcastDelegates: [SessionStarsDataSourceDelegate] = []
    
    func sessionStarsDidUpdate(dataSource: SessionStarsDataSource) {
        for delegate in broadcastDelegates {
            delegate.sessionStarsDidUpdate(dataSource: dataSource)
        }
    }
}
