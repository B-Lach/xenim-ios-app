//
//  UIGradientView.swift
//  Xenim
//
//  Created by Stefan Trauth on 26/03/16.
//  Copyright © 2016 Stefan Trauth. All rights reserved.
//

import UIKit

@IBDesignable class UIGradientView: UIView {
    
    /// Gradient layer that is added on top of the view
    var gradientLayer: CAGradientLayer!
    
    /// Top color of the gradient layer
    var topColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.9) {
        didSet {
            gradientLayer.colors = [topColor.CGColor, bottomColor.CGColor]
        }
    }
    
    /// Bottom color of the gradient layer
    var bottomColor: UIColor = UIColor.clearColor() {
        didSet {
            gradientLayer.colors = [topColor.CGColor, bottomColor.CGColor]
        }
    }
    
    /// At which vertical point the layer should end
    var bottomYPoint: CGFloat = 1 {
        didSet {
            gradientLayer.endPoint = CGPoint(x: 0, y: bottomYPoint)
        }
    }
    
    /**
     Sets up the gradient layer
     */
    func setupGradientLayer() {
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [topColor.CGColor, bottomColor.CGColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: bottomYPoint)
        layer.addSublayer(gradientLayer)
    }
    
    /**
     Lays out all the subviews it has, in our case the gradient layer
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = frame
    }
    
    /**
     Initialises the view
     
     - parameter aDecoder: aDecoder
     
     - returns: self
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradientLayer()
    }
    
    /**
     Initialises the view
     
     - parameter frame: frame to use
     
     - returns: self
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
