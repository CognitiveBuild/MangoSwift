//
//  ActionButton.swift
//  Mango
//
//  Created by Wesley Sui on 06/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class ActionButton: UIButton {
    
    //MARK: Inspectables
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }
    
    @IBInspectable var actionBackgroundColor: UIColor? = StyleKit.actionButtonRed {
        didSet {
            backgroundColor = actionBackgroundColor
        }
    }
    
    @IBInspectable var idleBackgroundColor: UIColor? = StyleKit.actionButtonGreen {
        didSet {
            backgroundColor = idleBackgroundColor
        }
    }
    
    @IBInspectable var rippleLineWidth: CGFloat = 15
    
    // MARK: private variables
    fileprivate var isActionInProgress: Bool = false
    var backLayer: CALayer?
    var ripples = [CALayer]()
    var originalCornerRadius: CGFloat = 0
    var originalBorderColor = UIColor.clear.cgColor
    var originalBorderWidth: CGFloat = 0
    var originalTitleColor = UIColor.white
    
    // MARK: override
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setup()
    }
    
    func setup() {
        addTarget(self, action: #selector(ActionButton.onClicked), for: UIControlEvents.touchUpInside)
    }
    
    func onClicked() {
        
        self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 100.0,
                       options: UIViewAnimationOptions.curveEaseInOut,
                       animations: {
                        self.transform = CGAffineTransform.identity
        }, completion: {
            (finished) -> Void in
        })
    }
    
    fileprivate func createBackLayer() -> CALayer {
        let backlayer = CALayer()
        backlayer.masksToBounds = true
        backlayer.frame = bounds
        
        backlayer.backgroundColor = actionBackgroundColor!.cgColor
        
        backlayer.borderWidth = originalBorderWidth
        backlayer.borderColor = originalBorderColor
        
        layer.addSublayer(backlayer)
        return backlayer
    }
    
    fileprivate func getNewBounds() -> CGRect {
        let size = min(layer.bounds.height, layer.bounds.width)
        return CGRect(x: 0, y: 0, width: size, height: size)
    }
    
    fileprivate func backupOriginalStatus() {
        originalBorderWidth = layer.borderWidth
        originalTitleColor = self.titleColor(for: .normal)!
        originalBorderColor = layer.borderColor!
        originalCornerRadius = layer.cornerRadius
    }
    
    fileprivate func restoreOriginalStatus() {
        layer.backgroundColor = UIColor.clear.cgColor
        layer.borderColor = originalBorderColor
        layer.borderWidth = originalBorderWidth
        setTitleColor(originalTitleColor, for: .normal)
        backgroundColor = idleBackgroundColor
    }
    
    fileprivate func startAnimating() {
        self.clipsToBounds = false
        var anim = CABasicAnimation(keyPath: "transform.scale")
//        anim.fromValue = 1
//        anim.toValue = 0
//        anim.duration = 0.2
//        anim.isRemovedOnCompletion = false
//        anim.fillMode = kCAFillModeForwards
//        backLayer!.add(anim, forKey: "scale")
        
        backLayer!.cornerRadius = originalCornerRadius
        anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = 0.2
        anim.isRemovedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        backLayer!.add(anim, forKey: "scale")
        
        //ripple
        GCD.delay(0.0) { Void in
            self.rippleAnimation()
        }
        
        GCD.delay(2.0) { Void in
            self.rippleAnimation()
        }
    }
    
    fileprivate func rippleAnimation() {
        guard let backLayer = self.backLayer else { return }
        
        let circle = CAShapeLayer()
        let center = CGPoint(x: layer.bounds.width / 2, y: layer.bounds.width / 2)
        let radius = backLayer.bounds.width
        circle.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle: CGFloat(2 * M_PI), clockwise: false).cgPath
        circle.frame = backLayer.frame
        
        circle.fillColor = UIColor.clear.cgColor
        circle.strokeColor = actionBackgroundColor!.cgColor
        circle.lineWidth = rippleLineWidth
        
        self.layer.addSublayer(circle)
        
        let animScale = CABasicAnimation(keyPath: "transform.scale")
        animScale.fromValue = 0
        animScale.toValue = 1
        
        circle.transform = CATransform3DMakeScale(1.0,1.0,1.0)
        circle.add(animScale, forKey: "scale")
        
        let animAlpha = CABasicAnimation(keyPath: "opacity")
        animAlpha.fromValue = 1
        animAlpha.toValue = 0
        animAlpha.isRemovedOnCompletion = false
        animAlpha.fillMode = kCAFillModeForwards
        
        circle.add(animAlpha, forKey: "alpha")
        
        let animGroup = CAAnimationGroup()
        animGroup.animations = [animScale,animAlpha]
        animGroup.repeatCount = Float.infinity
        animGroup.duration = 3
        circle.add(animGroup, forKey: "")
        
        ripples.append(circle)
    }
    
    // MARK: public API
    open func  startAction() {
        if isActionInProgress  { return }
        
        isActionInProgress = true
        
        //backup
        backupOriginalStatus()
        
        //clear
        backgroundColor = UIColor.clear
        layer.borderColor = UIColor.clear.cgColor
        setTitleColor(UIColor.clear, for: .normal)
        
        //backlayer
        backLayer = createBackLayer()

        self.startAnimating()
        
    }
    
    open func stopAction(_ animated: Bool) {
        if !isActionInProgress { return }
        
        isActionInProgress = false
        
        //remove ripples
        for subLayer in ripples {
            subLayer.removeAllAnimations()
            subLayer.removeFromSuperlayer()
        }
        
        //reset
        if animated {
            let animRadius = CABasicAnimation(keyPath: "cornerRadius")
            animRadius.toValue = layer.cornerRadius
            
            let animation = CABasicAnimation(keyPath: "bounds")
            animation.toValue = NSValue(cgRect: layer.bounds)
            
            let animScale = CABasicAnimation(keyPath: "transform.scale")
            animScale.fromValue = 0
            animScale.toValue = 1
            
            let animGroup = CAAnimationGroup()
            animGroup.animations = [animRadius,animation,animScale]
            animGroup.duration = 0.3
            animGroup.fillMode = kCAFillModeForwards
            animGroup.isRemovedOnCompletion = false
            
            animGroup.completion = {
                finished in
                self.backLayer!.removeAllAnimations()
                self.backLayer!.removeFromSuperlayer()
                self.backLayer = nil
                self.restoreOriginalStatus()
            }
            backLayer!.add(animGroup, forKey: "group")
            
        }else {
            self.backLayer!.removeAllAnimations()
            self.backLayer!.removeFromSuperlayer()
            self.backLayer = nil
            self.restoreOriginalStatus()
        }
    }
    
}
