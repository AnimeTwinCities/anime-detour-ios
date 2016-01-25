//
//  ImageFaceDetector.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/24/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

class ImageFaceDetector {
    private let detectionQueue: dispatch_queue_t
    
    private lazy var context = CIContext(options: [kCIContextUseSoftwareRenderer : NSNumber(bool: true)])
    private lazy var detector: CIDetector = CIDetector(ofType: CIDetectorTypeFace, context: self.context, options: [:])
    
    init(detectionQueue: dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
        self.detectionQueue = detectionQueue
    }
    
    /**
     Find the bounds of a face in `image`. If more than one face is detected,
     an arbitrary face's bounds will provided.
     
     - param: image The image to search for a face in.
     - param: completion A completion block to accept the detected face's bounds,
     if a face was found. May be called on a different thread, or not at all.
     */
    func findFace(image: UIImage, completion: (CGRect?) -> Void) {
        guard let ciImage = image.CGImage.map({ CIImage(CGImage: $0) }) else {
            completion(nil)
            return
        }
        
        dispatch_async(detectionQueue) { [detector] () -> Void in
            let features = detector.featuresInImage(ciImage)
            
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
