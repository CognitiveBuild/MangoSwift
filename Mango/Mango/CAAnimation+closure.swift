//
//  CAAnimation+closure.swift
//  Mango
//
//  Created by Wesley Sui on 06/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

/**
 *  CAAnimation Delegation class implementation
 */
class AnimationDelegate: NSObject, CAAnimationDelegate {
    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var start: (() -> Void)?
    
    /// completion: A block (closure) object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished.
    var completion: ((Bool) -> Void)?
    
    /// startTime: animation start date
    fileprivate var startTime: Date!
    fileprivate var animationDuration: TimeInterval!
    fileprivate var animatingTimer: Timer!
    
    /// animating: A block (closure) object to be executed when the animation is animating. This block has no return value and takes a single CGFloat argument that indicates the progress of the animation (From 0 ..< 1)
    var animating: ((CGFloat) -> Void)? {
        willSet {
            if animatingTimer == nil {
                animatingTimer = Timer(timeInterval: 0, target: self, selector: #selector(AnimationDelegate.animationIsAnimating(_:)), userInfo: nil, repeats: true)
            }
        }
    }
    
    /**
     Called when the animation begins its active duration.
     
     :param: theAnimation the animation about to start
     */
    func animationDidStart(_ theAnimation: CAAnimation) {
        start?()
        if animating != nil {
            animationDuration = theAnimation.duration
            startTime = Date()
            RunLoop.current.add(animatingTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    /**
     Called when the animation completes its active duration or is removed from the object it is attached to.
     
     :param: theAnimation the animation about to end
     :param: finished     A Boolean value indicates whether or not the animations actually finished.
     */
    func animationDidStop(_ theAnimation: CAAnimation, finished: Bool) {
        completion?(finished)
        animatingTimer?.invalidate()
    }
    
    /**
     Called when the animation is ongoing
     
     :param: timer timer
     */
    @objc func animationIsAnimating(_ timer: Timer) {
        let progress: CGFloat = CGFloat(Date().timeIntervalSince(startTime) / animationDuration)
        if progress < 1.0 {
            animating?(progress)
        }
    }
}

extension CAAnimation {
    // Add start and completion property for CAAnimation Class
    /// start: A block (closure) object to be executed when the animation starts. This block has no return value and takes no argument.
    var start: (() -> Void)? {
        set {
            if self.delegate == nil || !self.delegate!.isKind(of: AnimationDelegate.self) {
                self.delegate = AnimationDelegate()
            }
            (self.delegate as! AnimationDelegate).start = newValue
        }
        
        get {
            if (self.delegate != nil) && self.delegate!.isKind(of: AnimationDelegate.self) {
                return (self.delegate as! AnimationDelegate).start
            }
            return nil
        }
    }
    
    /**
     Convenience method for setting start
     * Use func can have a code auto completion
     
     :param: start start closure
     */
    func setStartClosure(start: @escaping () -> Void) {
        self.start = start
    }
    
    /// completion: A block (closure) object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished.
    var completion: ((Bool) -> Void)? {
        set {
            if self.delegate == nil || !self.delegate!.isKind(of: AnimationDelegate.self) {
                self.delegate = AnimationDelegate()
            }
            (self.delegate as! AnimationDelegate).completion = newValue
        }
        
        get {
            if (self.delegate != nil) && self.delegate!.isKind(of: AnimationDelegate.self) {
                return (self.delegate as! AnimationDelegate).completion
            }
            return nil
        }
    }
    
    /**
     Convenience method for setting completion
     
     :param: completion completion closure
     */
    func setCompletionClosure(_ completion: @escaping ((Bool) -> Void)) {
        self.completion = completion
    }
    
    /// animating: A block (closure) object to be executed when the animation is animating. This block has no return value and takes a single CGFloat argument that indicates the progress of the animation (From 0 ..< 1)
    var animating: ((CGFloat) -> Void)? {
        set {
            if self.delegate == nil || !self.delegate!.isKind(of: AnimationDelegate.self) {
                self.delegate = AnimationDelegate()
            }
            (self.delegate as! AnimationDelegate).animating = newValue
        }
        
        get {
            if (self.delegate != nil) && self.delegate!.isKind(of: AnimationDelegate.self) {
                return (self.delegate as! AnimationDelegate).animating
            }
            return nil
        }
    }
    
    /**
     Convenience method for setting animating
     
     :param: animating animating closure
     */
    func setAnimatingClosure(_ animating: @escaping ((CGFloat) -> Void)) {
        self.animating = animating
    }
}

extension CALayer {
    /**
     Add the specified animation object to the layer’s render tree. Could provide a completion closure.
     
     :param: anim       The animation to be added to the render tree. This object is copied by the render tree, not referenced. Therefore, subsequent modifications to the object are not propagated into the render tree.
     :param: key        A string that identifies the animation. Only one animation per unique key is added to the layer. The special key kCATransition is automatically used for transition animations. You may specify nil for this parameter.
     :param: completion A block object to be executed when the animation ends. This block has no return value and takes a single Boolean argument that indicates whether or not the animations actually finished before the completion handler was called. Default value is nil.
     */
    func addAnimationWithCompletion(_ anim: CAAnimation!, forKey key: String!, withCompletion completion: ((Bool) -> Void)? = nil) {
        anim.completion = completion
        self.add(anim, forKey: key)
    }
}
