//
//  Camera.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/13/20.
//

import UIKit
import AVFoundation

final class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    var view: AVCaptureVideoPreviewLayer

    private let queue = DispatchQueue(label: "CameraOutput", attributes: [], autoreleaseFrequency: .workItem)

    typealias CameraCompletion = (CMSampleBuffer) -> Void

    private var completion: CameraCompletion?

    override init() {
        view = AVCaptureVideoPreviewLayer(session: session)
        view.session = session
        view.videoGravity = .resizeAspect
        super.init()

        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            do {
                let videoIn = try AVCaptureDeviceInput(device: videoDevice)
                session.beginConfiguration()

                if videoDevice.supportsSessionPreset(.hd1920x1080) {
                    session.sessionPreset = .hd1920x1080
                } else {
                    session.sessionPreset = .high
                }

                if (session.canAddInput(videoIn)) {
                    session.addInput(videoIn)
                }

                let output = AVCaptureVideoDataOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                output.alwaysDiscardsLateVideoFrames = true
                output.videoSettings = [
                    String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                ]
                output.setSampleBufferDelegate(self, queue: queue)

                let captureConnection = output.connection(with: .video)
                captureConnection?.preferredVideoStabilizationMode = .standard
                captureConnection?.isEnabled = true
                captureConnection?.videoOrientation = .portrait
                session.commitConfiguration()
            } catch {
                print("AVCaptureDeviceInput error \(error)")
            }

            session.startRunning()
        } else {
            debugPrint("No camera found on device!.")
        }
    }

    func captureOutputCompletion(_ completion: @escaping CameraCompletion) {
        self.completion = completion
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.completion?(sampleBuffer)
    }

    func viewRectForVisionRect(_ visionRect: CGRect) -> CGRect {
        let flippedRect = visionRect.applying(CGAffineTransform.verticalFlip)
        let viewRect = view.layerRectConverted(fromMetadataOutputRect: flippedRect)
        return viewRect
    }
}
