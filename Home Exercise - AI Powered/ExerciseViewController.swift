//
//  ViewController.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/11/20.
//

import UIKit
import AVFoundation

enum VideoAsset: String {
    case resting
    case squat
    case test


    private var url: URL? {
        guard let path = Bundle.main.path(forResource: self.rawValue, ofType:"mov") else {
            debugPrint( "\(self.rawValue)) not found")
            return nil
        }

        let url = URL(fileURLWithPath: path)
        return url
    }

    var player: AVPlayer? {
        guard let url = self.url else { return nil }
        let player = AVPlayer(url: url)
        return player
    }
}

class ExerciseViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!

    @IBOutlet weak var cameraView: UIView!

    @IBOutlet weak var predictionLabel: UILabel!

    let camera = Camera()

    let predictor = Predictor()

    let bodyView = BodyOverlayView()

    let playerLayer = AVPlayerLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        //let videoLayer = getVideoLayer(for: VideoAsset.resting.player)
        //videoView.layer.addSublayer(videoLayer)
        setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoView.layer.sublayers?.first?.frame.origin = CGPoint(x: 0, y: 0)
        videoView.layer.sublayers?.first?.frame.size = videoView.frame.size
        camera.videoPreviewLayer.frame.origin = CGPoint(x: 0, y: 0)
        camera.videoPreviewLayer.frame.size = cameraView.frame.size
    }

    private func getVideoLayer(for player: AVPlayer?) -> AVPlayerLayer {
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspectFill

        playerLayer.player = player
        playerLayer.player?.play()

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: playerLayer.player?.currentItem,
                                               queue: .main) { [weak self] _ in
            self?.playerLayer.player?.seek(to: CMTime.zero)
            self?.playerLayer.player?.play()
        }

        return playerLayer
    }

    private func setupCamera() {
        camera.videoPreviewLayer.frame = cameraView.frame
        cameraView.layer.addSublayer(camera.videoPreviewLayer)
        cameraView.addSubview(bodyView)

        camera.captureOutputCompletion { [weak self] buffer in
            guard let `self` = self else { return }

            // Get the frame of rendered view
            DispatchQueue.main.async {
                let normalizedFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
                self.bodyView.frame = self.camera.viewRectForVisionRect(normalizedFrame)
            }

            if let poseObservation = try? self.predictor.performBodyPoseRequest(buffer) {
                // Fetch body joints from the observation and overlay them on the player.
                let joints = getBodyJointsFor(observation: poseObservation)
                DispatchQueue.main.async {
                    self.bodyView.joints = joints
                }
            }

            let prediction = try? self.predictor.makePrediction(buffer)

            let label = prediction?.label ?? "..."

            DispatchQueue.main.async {
                self.predictionLabel.text = "pose:\(label)"

                if let asset = VideoAsset(rawValue: label) {
                    self.playerLayer.player = asset.player
                }

            }
        }
    }
}

