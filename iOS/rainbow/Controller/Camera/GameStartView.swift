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
    //swiftlint:disable weak_delegate
    weak var delegate: GameStartViewDelegate?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var gameStartButton: UIButton {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.midX - 100, y: UIScreen.main.bounds.midY - 100, width: 200, height: 200))
        button.layer.cornerRadius = self.frame.size.height / 2
        button.setTitle("Start Searching", for: .normal)
        button.setTitleColor(UIColor.RainbowColors.orange, for: .normal) // Y U NO WORK
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 2.0
        button.titleLabel?.font = UIFont.RainbowFonts.bold(size: 30)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
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
        //self.gameStartButton.backgroundColor = UIColor.RainbowColors.orange
        // Y DIS NO WORK
    }
}
