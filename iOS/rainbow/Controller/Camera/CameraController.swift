//
//  CameraController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import Lumina
import SpriteKit
import AudioToolbox

enum GameCameraState {
    case shouldStartNewGame // when the game should be started, or has finished and could be restarted
    case nothingDetected // normal camera state, hunting for objects
    case detectionInProgress // it's fair to assume they should detect three consecutive frames since this happens fast
    case objectDetected // this should last one second when the fireworks are going off
}

class CameraController: LuminaViewController {
    var cachedScoreEntry: ScoreEntry?
    var checkTimer: Timer?
    var gameState = GameCameraState.shouldStartNewGame
    var consecutiveDetectionCount = 0
    var gameConfigObjects: [ObjectConfig]? {
        do {
            let objects = try GameConfig.load()
            return objects.sorted { $0.name < $1.name }
        } catch {
            return nil
        }
    }
    var iconImageViews = [String: UIImageView]()
    var iconCheckImageViews = [String: UIImageView]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.streamingModelTypes = [ProjectRainbowModel_1753554316()]
        self.setShutterButton(visible: false)
        self.setTorchButton(visible: true)
        self.setCancelButton(visible: false)
        self.setSwitchButton(visible: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawInitialUI()
    }
    
    private func drawInitialUI() {
        guard let gameConfigObjects = gameConfigObjects else {
            return
        }
        var topY = UIScreen.main.bounds.minY + self.navigationController!.navigationBar.frame.height + 110
        let iconX = UIScreen.main.bounds.maxX - 50
        let checkX = UIScreen.main.bounds.maxX - 80
        for object in gameConfigObjects {
            let imageView = UIImageView(frame: CGRect(x: iconX, y: topY, width: 40, height: 40))
            imageView.contentMode = .scaleAspectFill
            imageView.image = object.getWhiteImage()
            imageView.alpha = 0.7
            self.view.addSubview(imageView)
            iconImageViews[object.name] = imageView
            let imageCheckView = UIImageView(frame: CGRect(x: checkX, y: topY + 12, width: 20, height: 20))
            imageCheckView.contentMode = .scaleAspectFill
            imageCheckView.image = #imageLiteral(resourceName: "checkmark")
            imageCheckView.alpha = 0.0
            self.view.addSubview(imageCheckView)
            iconCheckImageViews[object.name] = imageCheckView
            topY += 60
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        determineGameState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        checkTimer?.invalidate()
        pauseCamera()
    }
    
    func determineGameState() {
        do {
            let savedGames = try ScoreEntry.ClientPersistence.getAll()
            if savedGames.count == 0 {
                //showStartView()// something is up with this method for now
                startnewGame()
            } else {
                let userGames = savedGames.filter { $0.username == "dokun1" } // this is just for now
                if userGames.count == 0 {
                    showStartView()
                } else {
                    if let firstGame = userGames.first {
                        self.cachedScoreEntry = firstGame
                        if let objects = firstGame.objects {
                            for object in objects {
                                updateObjectUI(for: object.name)
                            }
                        }
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
        gameState = .nothingDetected
        checkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
        checkTimer?.fire()
        bringAllIconsToFront()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startCamera()
        }
    }
    
    @objc func updateTimeLabel() {
        if gameState == .nothingDetected {
            self.textPrompt = GameTimer.getTimeElapsedString(for: cachedScoreEntry)
        }
    }
}

// MARK: State Check On Load

extension CameraController {
    fileprivate func bringAllIconsToFront() {
        for pair in iconImageViews {
            view.bringSubview(toFront: pair.value)
        }
        for pair in iconCheckImageViews {
            view.bringSubview(toFront: pair.value)
        }
    }
    
    fileprivate func gameCurrentlyInProgress() -> Bool {
        return true
        // leaving this commented for now because something is up with showing the what is supposed to be overly simple "start game button"
//        guard let cachedScoreEntry = cachedScoreEntry else {
//            return false
//        }
//        if cachedScoreEntry.startDate != nil {
//            return cachedScoreEntry.finishDate == nil
//        } else {
//            return false
//        }
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

extension CameraController: LuminaDelegate {
    func streamed(videoFrame: UIImage, with predictions: [LuminaRecognitionResult]?, from controller: LuminaViewController) {
        if gameState == .objectDetected {
            return
        }
        guard let bestName = predictions?.first?.predictions?.first?.name else {
            return
        }
        guard let bestConfidence = predictions?.first?.predictions?.first?.confidence else {
            return
        }
        if bestConfidence >= 0.9 {
            var objects = [ObjectEntry]()
            if let cachedObjects = cachedScoreEntry?.objects {
                objects = cachedObjects
            }
            let filteredObjects = objects.filter { $0.name == bestName }
            if filteredObjects.count > 0 {
                continueScanning()
                return
            }
            guard let gameConfigObjects = gameConfigObjects else {
                continueScanning()
                return
            }
            let filteredConfigObjects = gameConfigObjects.filter { $0.name == bestName }
            if filteredConfigObjects.count == 0 || filteredConfigObjects.count > 1 {
                continueScanning()
                return
            }
            gameState = .detectionInProgress
            self.textPrompt = "Detecting: \(bestName)"
            consecutiveDetectionCount += 1
            if consecutiveDetectionCount > 4 {
                objectDetected(label: bestName)
            }
        } else {
            continueScanning()
        }
    }
    
    private func continueScanning() {
        self.consecutiveDetectionCount = 0
        gameState = .nothingDetected
    }
}

extension CameraController {
    func objectDetected(label: String) {
        self.consecutiveDetectionCount = 0
        gameState = .objectDetected
        updateObjectUI(for: label)
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func updateObjectUI(for label: String) {
        textPrompt = "You found the \(label)!"
        animateCheckImage(iconCheckImageViews[label])
        updateEntry(for: label)
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateGameState), userInfo: nil, repeats: false)
    }
    
    private func updateEntry(for object: String) {
        guard var currentGame = cachedScoreEntry else {
            return
        }
        var objects = [ObjectEntry]()
        if let cachedObjects = currentGame.objects {
            objects = cachedObjects
        }
        objects.append(ObjectEntry(name: object, timestamp: Date()))
        currentGame.objects = objects
        do {
            try ScoreEntry.ClientPersistence.save(entry: currentGame)
            cachedScoreEntry = currentGame
        } catch let error {
            print("Received error trying to save game: \(error.localizedDescription)")
        }
    }
    
    private func animateCheckImage(_ view: UIImageView?) {
        guard let view = view else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            view.alpha = 0.7
        }
    }
    
    @objc private func updateGameState() {
        gameState = .nothingDetected
    }
}
