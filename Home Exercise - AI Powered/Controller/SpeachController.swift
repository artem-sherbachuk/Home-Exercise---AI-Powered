//
//  SpeachController.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/19/20.
//

import AVFoundation

final class SpeachController {

    let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)

        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")

        synthesizer.speak(utterance)
    }
}
