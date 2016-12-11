//
//  PhotoDownloader.swift
//  Anime Detour
//
//  Created by Brendon Justin on 12/11/16.
//  Copyright © 2016 Anime Twin Cities, Inc. All rights reserved.
//

import UIKit
import CoreData

class PhotoDownloader {
    static var shared: PhotoDownloader = PhotoDownloader()
    
    let persistentContainer: NSPersistentContainer
    let urlSession: URLSession
    
    init(persistentContainer: NSPersistentContainer = AppDelegate.shared.persistentContainer, urlSession: URLSession = URLSession.shared) {
        self.persistentContainer = persistentContainer
        self.urlSession = urlSession
    }
    
    func downloadPhoto(at url: URL, completion: ((Result<UIImage>) -> Void)?) {
        let task = urlSession.dataTask(with: url) { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let strongSelf = self else {
                return
            }
            
            if let error = error {
                completion?(.error(error))
                return
            }
            
            guard let image = data.flatMap(UIImage.init) else {
                return
            }
            
            completion?(.success(image))
        }
        task.resume()
    }
}
