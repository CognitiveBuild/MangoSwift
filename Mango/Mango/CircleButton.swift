//
//  CircleButton.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

@IBDesignable class CircleButton: UIButton {
    
    private var backgroundLayer = CAShapeLayer()
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            backgroundLayer.lineWidth = borderWidth
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setup()
    }
    
    func setup() {
        backgroundLayer.bounds = bounds
        backgroundLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        let path = UIBezierPath(ovalInRect: CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)))
        backgroundLayer.path = path.CGPath
        backgroundLayer.strokeColor = UIColor.whiteColor().CGColor
        backgroundLayer.lineWidth = borderWidth
        backgroundLayer.fillColor = UIColor.clearColor().CGColor
        layer.addSublayer(backgroundLayer)
        
        let cornerRadius = bounds.size.width > bounds.size.height ? bounds.size.height/2 : bounds.size.width/2
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = cornerRadius > 0
    }


}
