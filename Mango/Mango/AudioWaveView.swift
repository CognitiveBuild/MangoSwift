//
//  AudioWaveView.swift
//  Mango
//
//  Created by Wesley Sui on 05/12/2016.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

@objc protocol AudioWaveView: class {
    func update(time:String, withWaveData data:[Float])
}

class WaveTimeView: UIView, AudioWaveView {
    @IBOutlet weak private var timeLabel: UILabel!
    @IBOutlet weak private var waveView: WaveView!
    
    func reset() {
        timeLabel.text = ""
        waveView.data = []
        waveView.setNeedsDisplay()
    }
    
    func update(time:String, withWaveData data:[Float]) {
        timeLabel.text = time
        waveView.data = data
        waveView.setNeedsDisplay()
    }
    
}

class WaveView: UIView {
    var data: [Float] = []
    var barColor = UIColor.white
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = self.bounds.height / 2
        self.clipsToBounds = true
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if data.count <= 0 {
            return
        }

        let wavePath = UIBezierPath()
        wavePath.lineWidth = 2.0
        wavePath.lineCapStyle = CGLineCap.butt
        barColor.setStroke()
        
        let startCoord = self.bounds.size.width - 4
        var index = data.count - 1
        var xCoord = startCoord
        while(xCoord>4) {
            var height: CGFloat = 1.0
            if index > 0 {
                index = index - 1
                height = CGFloat(data[index]) / 160 * self.bounds.size.height
            }
            
            let halfHeight = height/2.0
            wavePath.move(to: CGPoint(x: xCoord, y: self.bounds.height/2.0 - halfHeight))
            wavePath.addLine(to: CGPoint(x: xCoord, y:self.bounds.height/2.0 + halfHeight))
            
            wavePath.close()
            
            xCoord = xCoord - 3
        }
        
        wavePath.stroke()
    }
}
