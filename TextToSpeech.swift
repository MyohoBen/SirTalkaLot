//
//  TextToSpeech.swift
//  SirTalkaLot
//
//  Created by Ben Cady on 3/17/23.
//

import Foundation
import AVFoundation

class TextToSpeech {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let utterance = AVSpeechUtterance(string: text)
            self.synthesizer.speak(utterance)
        }
    }
}
