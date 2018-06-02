//
//  CameraController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import Lumina
import AudioToolbox
import SVProgressHUD
import VisualRecognitionV3

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
        VisualRecognitionUpdate.loadLatestModel(useCloudAPI: false) { model, _ in
            guard let model = model else {
                SVProgressHUD.showError(withStatus: "Could not load visual model from device")
                return
            }
            self.streamingModels = [LuminaModel(model: model, type: "WatsonML")]
        }
        self.setShutterButton(visible: false)
        self.setTorchButton(visible: true)
        self.setCancelButton(visible: false)
        self.setSwitchButton(visible: false)
        LuminaViewController.loggingLevel = .info
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawInitialUI()
    }
    
    private func drawInitialUI() {
        guard let gameConfigObjects = gameConfigObjects else {
            return
        }
        guard let navigationController = self.navigationController else {
            return
        }
        var topY = UIScreen.main.bounds.minY + navigationController.navigationBar.frame.height + 110
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        determineGameState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfLatestModelAvailable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        checkTimer?.invalidate()
    }
    
    func determineGameState() {
        do {
            let savedGame = try ScoreEntry.ClientPersistence.get()
            if savedGame.startDate == nil { // first game has not started
                showStartView()
            } else if savedGame.startDate != nil, savedGame.finishDate != nil { // game completed, should prompt for restart
                showStartView()
            } else { // the user has started a game because a start date exists
                self.cachedScoreEntry = savedGame
                if let objects = savedGame.objects {
                    for object in objects {
                        iconCheckImageViews[object.name]?.alpha = 0.7
                    }
                }
                continueGame()
            }
        } catch {
            showStartView()
        }
    }
    
    func startNewGame() {
        defer {
            continueGame()
        }
        var needsServerUpdate = true
        do {
            for view in iconCheckImageViews {
                view.1.alpha = 0.0
            }
            var savedScoreEntry = try ScoreEntry.ClientPersistence.get()
            if savedScoreEntry.finishDate != nil {
                needsServerUpdate = false
            }
            savedScoreEntry.startDate = Date()
            savedScoreEntry.finishDate = nil
            savedScoreEntry.objects = nil
            try ScoreEntry.ClientPersistence.save(entry: savedScoreEntry)
            cachedScoreEntry = savedScoreEntry
            
            if needsServerUpdate == false {
                return
            }
            //we don't want to send base64 string
            
            savedScoreEntry.avatarImage = nil
            
            //update the startDate to the cloud.            
            ScoreEntry.ServerCalls.update(entry: savedScoreEntry, completion: { entry, error in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "Could not start new game on server - keep playing!!")
                    print("error during initial user save: \(String(describing: error?.localizedDescription))")
                } else {
                    guard let entry = entry else {
                        SVProgressHUD.showError(withStatus: "Could not start new game on server - keep playing!!")
                        print("error during initial user save: \(String(describing: error?.localizedDescription))")
                        return
                    }
                    print("Successfully updated cloud database with startDate \(String(describing: entry.startDate))")
                }
            })
        } catch {
            SVProgressHUD.showError(withStatus: "Couldn't connect to the server - keep playing!")
        }
    }
    
    func continueGame() {
        gameState = .nothingDetected
        checkTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateTimeLabel), userInfo: nil, repeats: true)
        checkTimer?.fire()
        bringAllIconsToFront()
        self.startCamera()
    }
    
    @objc func updateTimeLabel() {
        if gameState == .nothingDetected {
            self.textPrompt = GameTimer.getTimeElapsedString(for: cachedScoreEntry)
        }
    }
    
    fileprivate func checkIfLatestModelAvailable() {
        let defaults = UserDefaults.standard
        guard let lastCheckDate = defaults.string(forKey: "lastModelCheckDate")?.dateFromISO8601 else {
            // this has never checked - log the first date and continually check whenever we load this screen again
            defaults.set(Date().iso8601, forKey: "lastModelCheckDate")
            defaults.synchronize()
            return
        }
        let interval = Date().timeIntervalSince(lastCheckDate)
        if interval > TimeInterval(60 * 60 * 24 * 7) {
            // its been 7 days since the last check for a fresh model, let's see if there's something new to download
            defaults.set(Date().iso8601, forKey: "lastModelCheckDate")
            defaults.synchronize()
            VisualRecognitionUpdate.checkNewModelAvailable { available in
                DispatchQueue.main.async {
                    if available { self.promptForLatestModel() }
                }
            }
        }
    }
    
    private func promptForLatestModel() {
        let alert = UIAlertController.init(title: "Load New Visual Model", message: "A new recognition model is available, and requires a download of 15-20 MB. Would you like to improve your gameplay?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "Download", style: .default) { _ in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            VisualRecognitionUpdate.loadLatestModel(useCloudAPI: true, completion: { model, _ in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let model = model {
                    SVProgressHUD.showSuccess(withStatus: "Latest model loaded")
                    self.streamingModels = [LuminaModel(model: model, type: "WatsonML")]
                } else {
                    SVProgressHUD.showError(withStatus: "Could not download - using existing model")
                }
            })
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
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
    
    fileprivate func hideStartView(passedView: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            passedView.alpha = 0.0
        }, completion: { _ in
            passedView.removeFromSuperview()
            self.startCamera()
            self.startNewGame()
        })
    }
    
    fileprivate func showStartView() {
        self.pauseCamera()
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
        hideStartView(passedView: passedView)
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
                defer {
                    continueScanning()
                }
                guard let foundObject = filteredObjects.first else {
                    return
                }
                self.textPrompt = "You already found the \(foundObject.name)!"
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
        if let point = iconCheckImageViews[label]?.center {
            Fireworks.show(for: self.view, at: point, with: UIColor.RainbowColors.red)
        }
        updateEntry(for: label)
        checkGameComplete()
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateGameState), userInfo: nil, repeats: false)
    }
    
    func checkGameComplete() {
        do {
            let config = try GameConfig.load()
            guard let objects = cachedScoreEntry?.objects else {
                return
            }
            if config.count == objects.count {
                guard var finishedGame = cachedScoreEntry else {
                    return
                }
                finishedGame.finishDate = Date()
                try ScoreEntry.ClientPersistence.save(entry: finishedGame)
                let savedGame = try ScoreEntry.ClientPersistence.get()
                if let startDate = savedGame.startDate, let finishDate = savedGame.finishDate {
                    //update the startDate to the cloud.
                    var savedGameCopy = savedGame
                    savedGameCopy.avatarImage = nil
                    ScoreEntry.ServerCalls.update(entry: savedGameCopy, completion: { entry, error in
                        if error != nil {
                            SVProgressHUD.showError(withStatus: "Couldn't connect to the server - keep playing!")
                            print("error during initial user save: \(String(describing: error?.localizedDescription))")
                        } else {
                            guard let entry = entry else {
                                SVProgressHUD.showError(withStatus: "Couldn't connect to the server - keep playing!")
                                print("error during initial user save: \(String(describing: error?.localizedDescription))")
                                return
                            }
                            print("Successfully updated cloud database with finished game \(String(describing: entry.finishDate))")
                        }
                    })
                    pauseCamera()
                    showStartView()
                    SVProgressHUD.showSuccess(withStatus: "Congratulations! You finished the game in \(GameTimer.getTimeFoundString(startDate: startDate, objectTimestamp: finishDate))! See how you rank in the leaderboard and try again.")
                    self.tabBarController?.selectedIndex = 3
                }
            }
        } catch {
            return
        }
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
            SVProgressHUD.showError(withStatus: "Received error trying to save game: \(error.localizedDescription)")
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
