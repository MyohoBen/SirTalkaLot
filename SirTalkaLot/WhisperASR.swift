//
//  WhisperASR.swift
//  SirTalkaLot
//
//  Created by Ben Cady on 3/17/23.
//

import Foundation
import AVFoundation
import Speech

class WhisperASR {
    private let recognizer: SFSpeechRecognizer
    private let audioEngine: AVAudioEngine

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.recognizer = SFSpeechRecognizer(locale: locale)!
        self.audioEngine = AVAudioEngine()
    }

    func startRecording(completion: @escaping (Result<String, Error>) -> Void, recordingStopped: @escaping () -> Void) {
        if audioEngine.isRunning {
            stopRecording()
        } else {
            startRecordingSession(completion: completion, recordingStopped: recordingStopped)
        }
    }


    private func startRecordingSession(completion: @escaping (Result<String, Error>) -> Void, recordingStopped: @escaping () -> Void) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!, resultHandler: { result, error in
            if let result = result {
                if !result.isFinal {
                    return
                }
                DispatchQueue.main.async {
                    recordingStopped()
                    completion(.success(result.bestTranscription.formattedString))
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    recordingStopped()
                    completion(.failure(error))
                }
            }
        })


        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowAirPlay, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            try audioEngine.start()
            print("Recording started")
        } catch {
            print("Failed to start recording session: \(error)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        print("Recording stopped")
    }
}

