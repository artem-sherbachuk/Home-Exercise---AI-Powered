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

    let predictor = Predictor()

    let bodyView = BodyOverlayView()

    let exerciseCounter = ExerciseCounter()

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

        exerciseCounter.shouldSpeachCount = true
        exerciseCounter.performActionWhen { [weak self] exerciseCount in
            guard let `self` = self else { return }
            self.updateProgressForExercise(count: exerciseCount)
        }
    }

    private func updateProgressForExercise(count: Int) {
        let exerciseCount = Float(count) * 0.1
        let newProgress = progressBar.progress + exerciseCount
        progressBar.setProgress(newProgress, animated: true)
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


            guard let prediction = try? self.predictor.makePrediction(buffer) else {
                return
            }

            let label = prediction.label

            DispatchQueue.main.async {
                self.predictionLabel.text = "\(label)"

                if label == "squat" {
                    self.exerciseCounter.count()
                } else  {
                    self.exerciseCounter.stopCount()
                }
            }
        }
    }
}
