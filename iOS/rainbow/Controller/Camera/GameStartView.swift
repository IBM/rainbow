//
//  GameStartView.swift
//  rainbow
//
//  Created by David Okun IBM on 5/13/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import UIKit

class GameStartView: UIView {
    //swiftlint:disable:previous
    weak var delegate: GameStartViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var gameStartButton: UIButton {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.midX - 100, y: UIScreen.main.bounds.midY - 100, width: 200, height: 200))
        button.layer.cornerRadius = 100
        button.setTitle("Play Now", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.borderColor = UIColor.RainbowColors.pale.cgColor
        button.layer.borderWidth = 8.0
        button.titleLabel?.font = UIFont.RainbowFonts.bold(size: 28)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor.RainbowColors.orange
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        return button
    }
    
    @objc func buttonTapped() {
        delegate?.gameStartViewButtonTapped(passedView: self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        self.backgroundColor = UIColor.white
        self.addSubview(gameStartButton)
    }
}
