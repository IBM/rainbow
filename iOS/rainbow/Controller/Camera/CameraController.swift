//
//  CameraController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import Lumina

enum GameCameraState {
    case shouldStartNewGame
    case nothingDetected
    case detectionInProgress // it's fair to assume they should detect three consecutive frames since this happens fast
    case objectDetected
}

class CameraController: LuminaViewController {
    var cachedScoreEntry: ScoreEntry?
    var checkTimer: Timer?
    @IBOutlet weak var appleImageView: UIImageView?
    @IBOutlet weak var appleCheckImageView: UIImageView?
    @IBOutlet weak var beeImageView: UIImageView?
    @IBOutlet weak var beeCheckImageView: UIImageView?
    @IBOutlet weak var jeansImageView: UIImageView?
    @IBOutlet weak var jeansCheckImageView: UIImageView?
    @IBOutlet weak var notebookImageView: UIImageView?
    @IBOutlet weak var notebookCheckImageView: UIImageView?
    @IBOutlet weak var plantImageView: UIImageView?
    @IBOutlet weak var plantCheckImageView: UIImageView?
    @IBOutlet weak var shirtImageView: UIImageView?
    @IBOutlet weak var shirtCheckImageView: UIImageView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.streamingModelTypes = [ProjectRainbowModel_1753554316()]
        self.setShutterButton(visible: false)
        self.setTorchButton(visible: true)
        self.setCancelButton(visible: false)
        self.setSwitchButton(visible: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            let savedGames = try ScoreEntry.ClientPersistence.getAll()
            if savedGames.count == 0 {
                //showStartView()
                startnewGame()
            } else {
                let userGames = savedGames.filter { $0.username == "dokun1" }
                if userGames.count == 0 {
                    showStartView()
                } else {
                    if let firstGame = userGames.first {
                        self.cachedScoreEntry = firstGame
                        continueGame()
                    } else {
                        showStartView()
                    }
                }
            }
        } catch let error {
            print("caught error: \(error) - starting new game")
            startnewGame()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseCamera()
        checkTimer?.invalidate()
    }
    
    func startnewGame() {
        cachedScoreEntry = ScoreEntry(id: "ksdhfiusegfio", username: "dokun1", startDate: Date(), finishDate: nil, deviceIdentifier: "guhdgsrg", avatarImage: nil, avatarURL: nil, objects: nil)
        guard let cachedScoreEntry = cachedScoreEntry else {
            return
        }
        do {
            try ScoreEntry.ClientPersistence.save(entry: cachedScoreEntry)
            continueGame()
        } catch let error {
            print("there was an error: \(error.localizedDescription)")
        }
    }
    
    func continueGame() {
        checkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
        checkTimer?.fire()
        bringAllIconsToFront()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startCamera()
        }
    }
    
    //swiftlint:disable cyclomatic_complexity
    func bringAllIconsToFront() {
        if let appleImageView = appleImageView {
            self.view.bringSubview(toFront: appleImageView)
        }
        if let appleCheckImageView = appleCheckImageView {
            self.view.bringSubview(toFront: appleCheckImageView)
        }
        if let beeImageView = beeImageView {
            self.view.bringSubview(toFront: beeImageView)
        }
        if let beeCheckImageView = beeCheckImageView {
            self.view.bringSubview(toFront: beeCheckImageView)
        }
        if let jeansImageView = jeansImageView {
            self.view.bringSubview(toFront: jeansImageView)
        }
        if let jeansCheckImageView = jeansCheckImageView {
            self.view.bringSubview(toFront: jeansCheckImageView)
        }
        if let notebookImageView = notebookImageView {
            self.view.bringSubview(toFront: notebookImageView)
        }
        if let notebookCheckImageView = notebookCheckImageView {
            self.view.bringSubview(toFront: notebookCheckImageView)
        }
        if let plantImageView = plantImageView {
            self.view.bringSubview(toFront: plantImageView)
        }
        if let plantCheckImageView = plantCheckImageView {
            self.view.bringSubview(toFront: plantCheckImageView)
        }
        if let shirtImageView = shirtImageView {
            self.view.bringSubview(toFront: shirtImageView)
        }
        if let shirtCheckImageView = shirtCheckImageView {
            self.view.bringSubview(toFront: shirtCheckImageView)
        }
    }
    
    @objc func updateTimeLabel() {
        print("firing timer: \(Date())")
        self.textPrompt = GameTimer.getTimeElapsedString(for: cachedScoreEntry)
    }
}

// MARK: State Check On Load

extension CameraController {
    fileprivate func gameCurrentlyInProgress() -> Bool {
        return true
        guard let cachedScoreEntry = cachedScoreEntry else {
            return false
        }
        if cachedScoreEntry.startDate != nil {
            return cachedScoreEntry.finishDate == nil
        } else {
            return false
        }
    }
    
    fileprivate func hideStartView(passedView: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            passedView.alpha = 0.0
        }, completion: { _ in
            passedView.removeFromSuperview()
            self.startCamera()
        })
    }
    
    fileprivate func showStartView() {
        let startView = GameStartView(frame: self.view.frame)
        startView.delegate = self
        startView.gameStartButton.backgroundColor = UIColor.RainbowColors.orange
        view.addSubview(startView)
    }
}

protocol GameStartViewDelegate: class {
    func gameStartViewButtonTapped(passedView: UIView)
}

extension CameraController: GameStartViewDelegate {
    func gameStartViewButtonTapped(passedView: UIView) {
        hideStartView(passedView: view)
    }
}

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
        button.setTitleColor(UIColor.RainbowColors.orange, for: .normal)
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
    }
}

extension CameraController: LuminaDelegate {
    func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
        guard let bestName = predictions?.first?.predictions?.first?.name else {
            return
        }
        guard let bestConfidence = predictions?.first?.predictions?.first?.confidence else {
            return
        }
        if bestConfidence >= 0.9 {
            self.textPrompt = "Detecting: \(bestName)"
        } else {
            //updateTimeLabel()
        }
    }
}
