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

    let exerciseModel = try? Exercises2(configuration: MLModelConfiguration())

    let humanBodyPoseRequest = VNDetectHumanBodyPoseRequest()

    var posesWindow: [VNRecognizedPointsObservation] = []

    private let predictionWindowSize = 45

    private let predictionWindowFrameUpdateRate = 2

    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6

    init()
    {
        posesWindow.reserveCapacity(predictionWindowSize)
    }

    @discardableResult func performBodyPoseRequest(_ sampleBuffer: CMSampleBuffer) throws -> VNRecognizedPointsObservation?
    {
        if let pose = try extractPose(from: sampleBuffer), pose.confidence > bodyPoseDetectionMinConfidence  {
            if posesWindow.count > predictionWindowSize {
                posesWindow.removeFirst(predictionWindowFrameUpdateRate)
            }
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
              let modelInput = prepareInputWithObservations(posesWindow), let exerciseModel = exerciseModel else {
            return nil
        }

        let prediction = try exerciseModel.prediction(poses: modelInput)

        let label = prediction.label
        let confidence = prediction.labelProbabilities[label] ?? 0

        return PredictionOutput(label: label, confidence: confidence)
    }

    private func extractPose(from sampleBuffer: CMSampleBuffer) throws -> VNRecognizedPointsObservation?
    {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .upMirrored)

        try handler.perform([humanBodyPoseRequest])

        let poses = humanBodyPoseRequest.results?.first as? VNRecognizedPointsObservation

        return poses
    }



    func prepareInputWithObservations(_ observations: [VNRecognizedPointsObservation]) -> MLMultiArray? {
        let numAvailableFrames = observations.count
        let observationsNeeded = predictionWindowSize
        var multiArrayBuffer = [MLMultiArray]()

        for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded) {
            let pose = observations[frameIndex]
            do {
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                continue
            }
        }


        /*
         // If poseWindow does not have enough frames (60) yet, we need to pad 0s
         if numAvailableFrames < observationsNeeded {
         for _ in 0 ..< (observationsNeeded - numAvailableFrames) {
         do {
         let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 18], dataType: .float)
         try resetMultiArray(oneFrameMultiArray)
         multiArrayBuffer.append(oneFrameMultiArray)
         } catch {
         continue
         }
         }
         }
         */

        if numAvailableFrames < observationsNeeded {
            return nil
        }

        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
    }

    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Float = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Float>(predictionWindow)
        pointer.initialize(repeating: value)
    }
}
