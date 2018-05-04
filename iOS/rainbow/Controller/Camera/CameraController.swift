//
//  CameraController.swift
//  rainbow
//
//  Created by David Okun IBM on 5/3/18.
//  Copyright © 2018 IBM. All rights reserved.
//

import Foundation
import Lumina

class CameraController: LuminaViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
        self.streamingModelTypes = [DefaultCustomModel_1753554316()]
        self.setShutterButton(visible: false)
        self.setTorchButton(visible: true)
        self.setCancelButton(visible: false)
        self.setSwitchButton(visible: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("switched to camera")
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
            self.textPrompt = "Detected: \(bestName) (\(bestConfidence))"
        } else {
            self.textPrompt = ""
        }
    }
}
