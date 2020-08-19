//
//  ViewController.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/11/20.
//

import UIKit

class ExerciseViewController: UIViewController {

    @IBOutlet weak var videoView: VideoView!

    @IBOutlet weak var cameraView: UIView!

    @IBOutlet weak var predictionLabel: UILabel!

    @IBOutlet weak var progressBar: ProgressBar!

    let camera = CameraController()

    let speach = SpeachController()

    let predictor = Predictor()

    let bodyView = BodyOverlayView()

    var squatCount = 0 {
        didSet {
            speach.speak("\(squatCount)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoView.layer.sublayers?.first?.frame.origin = CGPoint(x: 0, y: 0)
        videoView.layer.sublayers?.first?.frame.size = videoView.frame.size
        camera.view.frame.origin = CGPoint(x: 0, y: 0)
        camera.view.frame.size = cameraView.frame.size
    }

    private func setupUI() {
        setupCamera()
        videoView.player = VideoAsset.squat.player
    }

    private func setupCamera() {
        camera.view.frame = cameraView.frame
        cameraView.layer.addSublayer(camera.view)
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

                if label == "squat" {
                    let newProgress = self.progressBar.progress + 0.1
                    self.progressBar.setProgress(newProgress, animated: true)

                    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                           selector: #selector(self.updateSquatCount),
                                                           object: nil)
                    self.perform(#selector(self.updateSquatCount), with: nil, afterDelay: 0.2)
                }
            }
        }
    }

    @objc private func updateSquatCount() {
        self.squatCount += 1
    }
}

