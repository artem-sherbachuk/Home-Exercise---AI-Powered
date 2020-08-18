//
//  Predictor.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/12/20.
//

import Foundation
import CoreML
import Vision

final class Predictor {

    typealias PredictionOutput = (label: String, confidence: Double)

    let exercisenModel = try? Exercises(configuration: MLModelConfiguration())

    let humanBodyPoseRequest = VNDetectHumanBodyPoseRequest()

    var posesWindow: [VNRecognizedPointsObservation] = []

    private  let predictionWindowSize = 60

    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6

    init()
    {
        posesWindow.reserveCapacity(predictionWindowSize)
    }

    @discardableResult func performBodyPoseRequest(_ sampleBuffer: CMSampleBuffer) throws -> VNRecognizedPointsObservation?
    {
        if let pose = try extractPose(from: sampleBuffer)  {
            posesWindow.append(pose)
            return pose
        }
        return nil
    }

    var isReadyToMakePrediction: Bool
    {
        posesWindow.count == predictionWindowSize
    }

    func makePrediction(_ sampleBuffer: CMSampleBuffer) throws -> PredictionOutput?
    {
        guard isReadyToMakePrediction,
              let modelInput = prepareInputWithObservations(posesWindow), let exercisenModel = exercisenModel else {
            return nil
        }

        let prediction = try exercisenModel.prediction(poses: modelInput)

        let label = prediction.label
        let confidence = prediction.labelProbabilities[label] ?? 0

        posesWindow.removeFirst()

        return PredictionOutput(label: label, confidence: confidence)
    }

    private func extractPose(from sampleBuffer: CMSampleBuffer) throws -> VNRecognizedPointsObservation?
    {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)

        try handler.perform([humanBodyPoseRequest])

        let poses = humanBodyPoseRequest.results?.first as? VNRecognizedPointsObservation

        return poses
    }
}