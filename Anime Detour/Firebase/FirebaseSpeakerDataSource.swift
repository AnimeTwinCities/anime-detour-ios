
//
//  FirebaseSpeakerDataSource.swift
//  DevFest
//
//  Created by Brendon Justin on 1/2/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit
import FirebaseDatabase

/**
 Provides speakers from Firebase.
 */
class FirebaseSpeakerDataSource: SpeakerDataSource {
    private let databaseReference: FIRDatabaseReference
    
    weak var speakerDataSourceDelegate: SpeakerDataSourceDelegate?
    
    var numberOfSections: Int {
        return speakers.count
    }
    
    private var speakers: [SpeakerViewModel] = []
    
    init(databaseReference: FIRDatabaseReference = FIRDatabase.database().reference()) {
        self.databaseReference = databaseReference
        
        databaseReference.child("devfest2017").child("speakers").observe(.value) { [weak self] (snapshot: FIRDataSnapshot) in
            guard let dict = snapshot.value as? [String:Any], let strongSelf = self else {
                return
            }
            
            var newSpeakers: [SpeakerViewModel] = []
            
            for (key, value) in dict {
                if let dictValue = value as? [String:Any],
                    let viewModel = SpeakerViewModel(id: key, firebaseData: dictValue) {
                    newSpeakers.append(viewModel)
                }
            }
            
            let sortedSpeakers = newSpeakers.sorted(by: { (vmOne, vmTwo) -> Bool in
                return vmOne.speakerID < vmTwo.speakerID
            })
            strongSelf.speakers = sortedSpeakers
            strongSelf.speakerDataSourceDelegate?.speakerDataSourceDidUpdate()
        }
    }
    
    func title(forSection section: Int) -> String? {
        return nil
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return speakers.count
    }
    
    func viewModel(at indexPath: IndexPath) -> SpeakerViewModel {
        let vm = speakers[indexPath.item]
        return vm
    }
    
    func indexPathOfSpeaker(withSpeakerID speakerID: String) -> IndexPath? {
        let maybeIndex = speakers.index(where: { vm in vm.speakerID == speakerID })
        let indexPath = maybeIndex.map { return IndexPath(item: $0, section: 0) }
        
        return indexPath
    }
    
    func starSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return viewModel
    }
    
    func unstarSession(for viewModel: SessionViewModel) -> SessionViewModel {
        return viewModel
    }
}

extension SpeakerViewModel {
    init?(id: String, firebaseData dict: [String:Any]) {
        guard let name = dict["name"] as? String, let bio = dict["bio"] as? String else {
            return nil
        }
        
        let company: String? = dict["company"] as? String
        let twitter: String? = dict["twitter"] as? String
        let websiteString: String? = dict["website"] as? String
        let imageURLString: String? = dict["imageUrl"] as? String
        
        let website = websiteString.flatMap { return URL(string: $0) }
        let imageURL = imageURLString.flatMap { return URL(string: $0) }
        
        self.init(speakerID: id, name: name, bio: bio, company: company, imageURL: imageURL, twitter: twitter, website: website)
    }
}
