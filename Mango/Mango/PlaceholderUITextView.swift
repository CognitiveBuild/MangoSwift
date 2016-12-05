//
//  PlaceholderUITextView.swift
//  Mango
//
//  Created by Wesley Sui on 05/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

@IBDesignable class PlaceholderUITextView: UIView, UITextViewDelegate {

    var view: UIView?
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var labelPlaceholder: UILabel!
    
    @IBInspectable var placeholderText: String = "Enter data here ..." {
        didSet {
            labelPlaceholder.text = placeholderText
        }
    }
    
    func commonXibSetup() {
        guard let view = loadViewFromNib() else
        {
            return
        }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        textView.delegate = self
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PlaceholderUITextView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as? UIView
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonXibSetup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        commonXibSetup()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.hasText {
            labelPlaceholder?.isHidden = false
        }
        else {
            labelPlaceholder?.isHidden = true
        }
    }

}
