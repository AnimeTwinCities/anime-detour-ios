//
//  ImageFaceDetector.swift
//  Anime Detour
//
//  Created by Brendon Justin on 1/24/16.
//  Copyright © 2016 Anime Detour. All rights reserved.
//

import UIKit

class ImageFaceDetector {
    func findFace(image: UIImage) -> CGRect? {
        guard let ciImage = image.CIImage else {
            return nil
        }
        
        let context = CIContext(options: [:])
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [:])
        let features = detector.featuresInImage(ciImage)
        
        guard let face = features.first as? CIFaceFeature else {
            return nil
        }
        
        return face.bounds
    }
}
