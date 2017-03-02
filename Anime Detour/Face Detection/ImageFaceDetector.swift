//
//  ImageFaceDetector.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/24/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

class ImageFaceDetector {
    fileprivate let detectionQueue: DispatchQueue
    
    fileprivate lazy var context = CIContext(options: [kCIContextUseSoftwareRenderer : NSNumber(value: true)])
    fileprivate lazy var detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: self.context, options: [:])!
    
    init(detectionQueue: DispatchQueue = DispatchQueue.global(qos: .utility)) {
        self.detectionQueue = detectionQueue
    }
    
    /**
     Find the bounds of a face in `image`. If more than one face is detected,
     an arbitrary face's bounds will provided.
     
     - param: image The image to search for a face in.
     - param: completion A completion block to accept the detected face's bounds,
     if a face was found. May be called on a different thread, or not at all.
     */
    func findFace(_ image: UIImage, completion: @escaping (CGRect?) -> Void) {
        guard let ciImage = image.ciImage ?? image.cgImage.map({ CIImage(cgImage: $0) }) else {
            completion(nil)
            return
        }
        
        detectionQueue.async { [detector] () -> Void in
            let features = detector.features(in: ciImage)
            
            let face: CIFaceFeature?
            
            defer {
                let faceBounds = face?.bounds
                let flippedFaceBounds = faceBounds.map { CGRect(origin: CGPoint(x: $0.minX, y: image.size.height - $0.maxY), size: $0.size) }
                completion(flippedFaceBounds)
            }
            
            if let detected = features.first as? CIFaceFeature {
                face = detected
            } else {
                face = nil
            }
        }
    }
}
