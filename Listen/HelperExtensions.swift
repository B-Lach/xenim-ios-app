//
//  HelperExtensions.swift
//  Listen
//
//  Created by Stefan Trauth on 06/11/15.
//  Copyright © 2015 Stefan Trauth. All rights reserved.
//

import UIKit

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}


extension UIImage {
    
    func averageColor() -> UIColor {
        let rgba = UnsafeMutablePointer<CUnsignedChar>.alloc(4)
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context: CGContextRef = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, info.rawValue)!
        
        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), self.CGImage)
        
        if rgba[3] > 0 {
            let alpha: CGFloat = CGFloat(rgba[3]) / 255.0
            let multiplier: CGFloat = alpha / 255.0
            
            return UIColor(red: CGFloat(rgba[0]) * multiplier, green: CGFloat(rgba[1]) * multiplier, blue: CGFloat(rgba[2]) * multiplier, alpha: alpha)
        } else {
            return UIColor(red: CGFloat(rgba[0]) / 255.0, green: CGFloat(rgba[1]) / 255.0, blue: CGFloat(rgba[2]) / 255.0, alpha: CGFloat(rgba[3]) / 255.0)
        }
    }
}

extension UIColor {
    
    func isDarkColor() -> Bool {
        let componentColors = CGColorGetComponents(self.CGColor)
        
        var colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114))
        colorBrightness /= 1000
        if (colorBrightness < 0.5) {
            return true
        } else {
            return false
        }
    }
}