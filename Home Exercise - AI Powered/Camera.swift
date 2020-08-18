//
//  Camera.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/13/20.
//

import UIKit
import AVFoundation

final class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    var videoPreviewLayer: AVCaptureVideoPreviewLayer

    private let queue = DispatchQueue(label: "CameraOutput", attributes: [], autoreleaseFrequency: .workItem)

    typealias CameraCompletion = (CMSampleBuffer) -> Void

    private var completion: CameraCompletion?

    override init() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspect
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
                // Always process the frames
                captureConnection?.isEnabled = true

                let videoOrientation: AVCaptureVideoOrientation
                switch UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
                case .landscapeRight:
                    videoOrientation = .landscapeRight
                default:
                    videoOrientation = .portrait
                }

                captureConnection?.videoOrientation = videoOrientation

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
        let viewRect = videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: flippedRect)
        return viewRect
    }
}


extension CMSampleBuffer {
    var image: UIImage {
        let image = UIImageFromCMSamleBuffer(buffer: self)
        return image
    }
    private func UIImageFromCMSamleBuffer(buffer:CMSampleBuffer)-> UIImage {
        let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x:0,y:0,width:pixelBufferWidth, height:pixelBufferHeight)
        let ciContext = CIContext.init()
        let cgimage = ciContext.createCGImage(ciImage, from: imageRect )
        let image = UIImage(cgImage: cgimage!)
        let resisedImage = resizeImage(image: image, newWidth: 500)
        //print("resized image from camera \(resisedImage)")
        return resisedImage
    }
    private func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        image.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}


