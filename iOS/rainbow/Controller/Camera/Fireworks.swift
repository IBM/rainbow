//
//  Fireworks.swift
//  rainbow
//
//  Created by David Okun IBM on 5/16/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class Fireworks {
    static func show(for view: UIView, at point: CGPoint) {
        let emitter = CAEmitterLayer()
        emitter.frame = view.bounds
        emitter.renderMode = kCAEmitterLayerAdditive
        emitter.emitterPosition = point
        view.layer.addSublayer(emitter)
        
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "particle")?.cgImage
        cell.birthRate = 750
        cell.lifetime = 5.0
        cell.color = UIColor.RainbowColors.red.cgColor
        cell.alphaSpeed = -0.4
        cell.velocity = 50
        cell.velocityRange = 250
        cell.emissionRange = CGFloat(Double.pi) * 2.0
        
        emitter.emitterCells = [cell]
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            emitter.removeFromSuperlayer()
        }
    }
}
