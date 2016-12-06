//
//  GCD.swift
//  Mango
//
//  Created by Wesley Sui on 06/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class GCD {
    
    class func async(_ block: @escaping ()->()) {
        DispatchQueue.global().async(execute: block)
    }
    
    class func main(_ block: @escaping ()->()) {
        DispatchQueue.main.async(execute: block)
    }
    
    class func delay(_ delaySeconds: Double, block: @escaping ()->()) {
        let time = DispatchTime.now() + Double(Int64(delaySeconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }
}
