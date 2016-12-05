//
//  StyleKit.swift
//  Mango
//
//  Created by Wesley Sui on 05/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class StyleKit: NSObject {
    
    //// Cache
    private struct Cache {
        static var defaultTint: UIColor = UIColor(hexString: "#525860")
        static var red1: UIColor = UIColor(hexString: "#A10914")
        static var green1: UIColor = UIColor(hexString: "#177886")
    }
    
    //// Colors
    public class var defaultTint: UIColor { return Cache.defaultTint }
    
    public class var actionButtonRed: UIColor { return Cache.red1 }
    public class var actionButtonGreen: UIColor { return Cache.green1 }

}
