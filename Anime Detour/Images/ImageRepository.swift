//
//  ImageRepository.swift
//  DevFest
//
//  Created by Brendon Justin on 1/16/17.
//  Copyright © 2017 GDGConferenceApp. All rights reserved.
//

import UIKit

private class LockBox<Wrapped> {
    private let lock = NSLock()
    var wrapped: Wrapped
    
    init(wrapped: Wrapped) {
        self.wrapped = wrapped
    }
    
    /**
     Prone to deadlocking with careless use.
     */
    func withLock<U>(block: (inout Wrapped) -> U) -> U {
        lock.lock()
        let result = block(&wrapped)
        lock.unlock()
        return result
    }
}

class ImageRepository {
    private let urlSession: URLSession
    fileprivate let cacheDirectory: URL
    private let faceDetector: ImageFaceDetector
    fileprivate let fileManager: FileManager
    
    /**
     In-memory cache of images.
     */
    private var imagesByURL = LockBox(wrapped: [URL:UIImage]())
    
    /**
     In-memory cache of faces for each image. Also saves to disk.
     */
    fileprivate var facesByCachedImagePath: [String:CGRect]? {
        didSet {
            guard let facesByCachedImagePath = facesByCachedImagePath else {
                do {
                    try fileManager.removeItem(at: facesPlistPathURL)
                } catch {
                    NSLog("Couldn't remove faces plist")
                }
                
                return
            }
            
            // NSDictionary can't natively write CGRect's to a plist,
            // so convert our CGRect's to CFDictionary's first.
            var pathsToValues: [String:CFDictionary] = [:]
            for (key, val) in facesByCachedImagePath {
                pathsToValues[key] = val.dictionaryRepresentation
            }
            
            let nsDict = pathsToValues as NSDictionary
            nsDict.write(to: facesPlistPathURL, atomically: true)
        }
    }
    
    /**
     The URL to the faces plist on disk.
     Since this is inside the caches directory, it may change between runs of the app.
     */
    fileprivate var facesPlistPathURL: URL {
        let filename = "facesForImages.plist"
        let facesPathURL = cacheDirectory.appendingPathExtension(filename)
        return facesPathURL
    }
    
    /**
     - seealso: `facesPlistPathURL`
     */
    fileprivate var facesPlistPath: String {
        let facesPath = facesPlistPathURL.path
        return facesPath
    }
    
    init(urlSession: URLSession, cacheDirectory: URL, faceDetector: ImageFaceDetector, fileManager: FileManager = FileManager.default) {
        self.urlSession = urlSession
        self.cacheDirectory = cacheDirectory
        self.faceDetector = faceDetector
        self.fileManager = fileManager
        
        // Rely on the OS automatically removing us as an observer when we dealloc
        NotificationCenter.default.addObserver(self, selector: #selector(memoryWarning(note:)), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    @objc private func memoryWarning(note: Notification) {
        // Clear our in-memory image cache on memory warnings.
        imagesByURL.withLock {
            $0.removeAll()
        }
    }
    
    /**
     Get an image for the given URL. If an image is already downloaded, return that.
     In the case of an already available image, `completion` will never be called.
     
     If no image is already available, no image will be returned, and we will attempt
     to download the image.
     
     Multiple calls to this method may be inefficient, but will not clear a cached image
     if any of those calls succeeds in downloading it.
     
     - returns: A the image, if we already have it downloaded, plus the location of an arbitrary
        face in that image, and the task that is being used to download the image, in case one wants
        to cancel the download.
     
     */
    func image(at url: URL, completion: @escaping (UIImage?, CGRect?) -> Void) -> (UIImage?, CGRect?, URLSessionTask?) {
        let savedFaceRect = cachedFaceRect(forImageWithURL: url)
        
        // See if we have the image cached in memory before doing anything else.
        if let image = imagesByURL.withLock(block: { $0[url] }) {
            return (image, savedFaceRect, nil)
        }
        
        // See if we have the image cached to disk before trying to download it.
        let cachedImagePath = cachePath(imageURL: url)
        if fileManager.fileExists(atPath: cachedImagePath), let image = UIImage(contentsOfFile: cachedImagePath) {
            imagesByURL.withLock {
                $0[url] = image
            }
            return (image, savedFaceRect, nil)
        }
        
        // Download the image
        let task = urlSession.dataTask(with: url) { [weak self] (data, response, error) in
            guard let strongSelf = self else {
                return
            }
            
            guard let data = data else {
                if let error = error {
                    NSLog("Error downloading image: \(error) at URL: \(url)")
                }
                
                completion(nil, nil)
                return
            }
            
            guard let image = UIImage(data: data) else {
                NSLog("Couldn't create image from data at URL: \(url)")
                completion(nil, nil)
                return
            }
            
            // Always try to detect faces before returning downloaded images.
            strongSelf.faceDetector.findFace(image) { maybeFace in
                guard let strongSelf = self else {
                    return
                }
                
                // If we found a face, cache it.
                if let face = maybeFace {
                    strongSelf.storeFace(face, forImageWithURL: url)
                }
                
                // Cache the image data to disk before returning it
                strongSelf.fileManager.createFile(atPath: cachedImagePath, contents: data, attributes: nil)
                strongSelf.imagesByURL.withLock {
                    $0[url] = image
                }
                
                completion(image, maybeFace)
            }
        }
        
        task.resume()
        return (nil, nil, task)
    }
}

private extension ImageRepository {
    /**
     The filename to use when caching an image at `url` to disk.
     */
    func cacheFilename(for url: URL) -> String {
        let allowedSet = CharacterSet.alphanumerics
        let absoluteString = url.absoluteString
        if let percentEncoded = absoluteString.addingPercentEncoding(withAllowedCharacters: allowedSet) {
            return percentEncoded
        } else {
            // Per http://stackoverflow.com/a/33558934/1610271 some strings can return nil for `addingPercentEncoding(...)`,
            // so fall back to something reasonably likely to be unique.
            return url.lastPathComponent + "\(url.hashValue)"
        }
    }
    
    /**
     The full path, including the filename, to use when caching the image at `url` on disk.
     Since this is inside the caches directory, it may change between runs of the app.
     */
    func cachePath(imageURL url: URL) -> String {
        let imageCacheFilename = cacheFilename(for: url)
        let cachedImagePathURL = cacheDirectory.appendingPathComponent(imageCacheFilename)
        let cachedImagePath = cachedImagePathURL.path
        
        return cachedImagePath
    }
    
    /**
     The face rect that is cached for the image at `url`.
     */
    func cachedFaceRect(forImageWithURL url: URL) -> CGRect? {
        if facesByCachedImagePath == nil {
            createCachedImagesVar()
        }
        
        let cachedImagePath = cacheFilename(for: url)
        return facesByCachedImagePath?[cachedImagePath]
    }
    
    /**
     Cache a face rect for the image at `url`.
     */
    func storeFace(_ faceRect: CGRect, forImageWithURL url: URL) {
        if facesByCachedImagePath == nil {
            createCachedImagesVar()
        }
        
        let cachedImagePath = cacheFilename(for: url)
        facesByCachedImagePath?[cachedImagePath] = faceRect
    }
    
    /**
     Create our in-memory cache of face rects, from our disk cache of face rects.
     */
    func createCachedImagesVar() {
        let facesByPath: [String:CGRect]
        defer {
            facesByCachedImagePath = facesByPath
        }
        
        // If we don't have a faces plist on disk, bail early.
        guard fileManager.fileExists(atPath: facesPlistPath) else {
            facesByPath = [:]
            return
        }
        
        // Try to load our faces data from disk. Otherwise, delete the file that we found
        // so we won't try to use it again.
        if let maybePlist = NSDictionary(contentsOf: facesPlistPathURL), let typedPlist = maybePlist as? [String:CFDictionary] {
            var facesToRects: [String:CGRect] = [:]
            
            for (key, val) in typedPlist {
                facesToRects[key] = CGRect(dictionaryRepresentation: val)
            }
            
            facesByPath = facesToRects
        } else {
            do {
                try fileManager.removeItem(at: facesPlistPathURL)
            } catch {
                NSLog("Couldn't remove face rects plist")
            }
            
            facesByPath = [:]
        }
    }
}
