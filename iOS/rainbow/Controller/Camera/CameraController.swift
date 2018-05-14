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

enum RainbowDetectedObject: String {
    case apple = "Apple"
    case bee = "Bee"
    case jeans = "Jeans"
    case notebook = "Notebook"
    case plant = "Plant"
    case shirt = "Shirt"
}

class CameraController: LuminaViewController {
    var cachedScoreEntry: ScoreEntry?
    var checkTimer: Timer?
    var gameState = GameCameraState.shouldStartNewGame
    var consecutiveDetectionCount = 0
    
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
                let userGames = savedGames.filter { $0.username == "dokun1" }
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
        if gameState == .nothingDetected {
            self.textPrompt = GameTimer.getTimeElapsedString(for: cachedScoreEntry)
        }
    }
}

// MARK: State Check On Load

extension CameraController {
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
        switch label {
        case "Apple":
            animateCheckImage(appleCheckImageView)
            updateEntry(for: .apple)
        case "Bee":
            animateCheckImage(beeCheckImageView)
            updateEntry(for: .bee)
        case "Jeans":
            animateCheckImage(jeansCheckImageView)
            updateEntry(for: .jeans)
        case "Notebook":
            animateCheckImage(notebookCheckImageView)
            updateEntry(for: .notebook)
        case "Plant":
            animateCheckImage(plantCheckImageView)
            updateEntry(for: .plant)
        case "Shirt":
            animateCheckImage(shirtCheckImageView)
            updateEntry(for: .shirt)
        default:
            print("unknown object detected")
        }
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateGameState), userInfo: nil, repeats: false)
    }
    
    private func updateEntry(for object: RainbowDetectedObject) {
        guard var currentGame = cachedScoreEntry else {
            return
        }
        var objects = [ObjectEntry]()
        if let cachedObjects = currentGame.objects {
            objects = cachedObjects
        }
        objects.append(ObjectEntry(name: object.rawValue, timestamp: Date()))
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
