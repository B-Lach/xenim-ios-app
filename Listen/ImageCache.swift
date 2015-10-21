//
//  ImageCache.swift
//  Listen
//
//  Created by Stefan Trauth on 20/10/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import Foundation
import AlamofireImage

class ImageCache {
    
    static let sharedImageCache = AutoPurgingImageCache()
    
}