//
//  SpeakerDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 1/2/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit

protocol SpeakerDataSource: DataSource {
    var speakerDataSourceDelegate: SpeakerDataSourceDelegate? { get set }
    
    func viewModel(at indexPath: IndexPath) -> SpeakerViewModel
    func viewModel(forSpeakerID speakerID: String) -> SpeakerViewModel?
    func indexPathOfSpeaker(withSpeakerID speakerID: String) -> IndexPath?
}

// Default implementations
extension SpeakerDataSource {
    func viewModel(forSpeakerID speakerID: String) -> SpeakerViewModel? {
        guard let indexPath = indexPathOfSpeaker(withSpeakerID: speakerID) else {
            return nil
        }
        
        return viewModel(at: indexPath)
    }
}

protocol SpeakerDataSourceDelegate: class {
    func speakerDataSourceDidUpdate()
}

final class SpeakerFixture: SpeakerDataSource {
    static let speakers: [SpeakerViewModel] = [
        SpeakerViewModel(speakerID: "eins", name: "Spongebob Squarepants", bio: "Lives in a pineapple under the sea.", company: "Krusty Krab", imageURL: nil, twitter: nil, website: nil),
        SpeakerViewModel(speakerID: "swei", name: "Patrick Star", bio: "No, this is Patrick!", company: "n/a", imageURL: nil, twitter: nil, website: nil),
        SpeakerViewModel(speakerID: "drei", name: "Squidward Tentacles", bio: "Insufferable clarinet player.", company: "Krusty Krab", imageURL: nil, twitter: nil, website: nil),
        ]
    
    let numberOfSections: Int = 1
    
    weak var speakerDataSourceDelegate: SpeakerDataSourceDelegate?
    
    func numberOfItems(inSection section: Int) -> Int {
        return SpeakerFixture.speakers.count
    }
    
    func title(forSection section: Int) -> String? {
        return nil
    }

    func viewModel(at indexPath: IndexPath) -> SpeakerViewModel {
        return SpeakerFixture.speakers[indexPath.item]
    }
    
    func indexPathOfSpeaker(withSpeakerID speakerID: String) -> IndexPath? {
        let maybeIdx = SpeakerFixture.speakers.index(where: { vm in vm.speakerID == speakerID })
        let maybeIndexPath = maybeIdx.map { IndexPath(item: $0, section: 0) }
        return maybeIndexPath
    }
}
