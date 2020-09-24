//
//  ExerciseCounterr.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/20/20.
//

import Foundation


final class ExerciseCounter {

    typealias CounterUpdateCompletion = (Int) -> Void

    private let speach = SpeachController()

    var shouldSpeachCount: Bool = false

    var counterUpdateCompletion: CounterUpdateCompletion?

    var exerciseCount: Int = 0 {
        didSet {

            if exerciseCount != oldValue {

                if shouldSpeachCount {
                    speach.speak("\(exerciseCount)")
                }

                counterUpdateCompletion?(exerciseCount)
            }

        }
    }

    let restingQuotes = ["Давай приседай. Жги!", "Хватить отдыхать", "если ты не продолжишь я взломаю твой монобанк и потрачю все деньги на благотворительность", "давай ты сможешь", "продолжай"]

    private var isStartedCounting: Bool = false {
        didSet {
            if isStartedCounting == false && isStartedCounting != oldValue && shouldSpeachCount {
                let quotesIndexes: UInt32 = UInt32(restingQuotes.count - 1)
                let rundomQuote: Int = Int(arc4random_uniform(quotesIndexes))
                let quote = restingQuotes[rundomQuote]
                speach.speak(quote)
            }
        }
    }

    init() {
        speach.speak("инициализация")
    }

    func count() {
        if !isStartedCounting {
            isStartedCounting = true
            exerciseCount += 1
        }
    }

    func stopCount() {
        isStartedCounting = false
    }

    func performActionWhen(counterUpdate: @escaping CounterUpdateCompletion) {
        self.counterUpdateCompletion = counterUpdate
    }

}
