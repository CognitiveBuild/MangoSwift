//
//  CircleButton.swift
//  Mango
//
//  Created by Wesley Sui on 7/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

@IBDesignable class CircleButton: UIButton {
    
    fileprivate var backgroundLayer = CAShapeLayer()
    
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
        backgroundLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        backgroundLayer.path = path.cgPath
        backgroundLayer.strokeColor = UIColor.white.cgColor
        backgroundLayer.lineWidth = borderWidth
        backgroundLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(backgroundLayer)
        
        let cornerRadius = bounds.size.width > bounds.size.height ? bounds.size.height/2 : bounds.size.width/2
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = cornerRadius > 0
    }


}
