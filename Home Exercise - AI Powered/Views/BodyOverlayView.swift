import UIKit

class BodyOverlayView: UIView, AnimatedTransitioning {
    var joints: [String: CGPoint] = [:] {
        didSet {
            updatePathLayer()
        }
    }

    private let jointRadius: CGFloat = 3.0
    private let jointLayer = CAShapeLayer()
    private var jointPath = UIBezierPath()

    private let jointSegmentWidth: CGFloat = 10.0
    private let jointSegmentLayer = CAShapeLayer()
    private var jointSegmentPath = UIBezierPath()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    func resetView() {
        jointLayer.path = nil
        jointSegmentLayer.path = nil
    }

    private func setupLayer() {
        jointSegmentLayer.lineCap = .square
        jointSegmentLayer.lineWidth = jointSegmentWidth
        jointSegmentLayer.fillColor = UIColor.clear.cgColor
        jointSegmentLayer.strokeColor = UIColor.systemRed.withAlphaComponent(0.7).cgColor
        layer.addSublayer(jointSegmentLayer)
        let jointColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        jointLayer.strokeColor = jointColor
        jointLayer.fillColor = jointColor
        layer.addSublayer(jointLayer)
    }

    private func updatePathLayer() {
        let flipVertical = CGAffineTransform.verticalFlip
        let scaleToBounds = CGAffineTransform(scaleX: bounds.width, y: bounds.height)
        jointPath.removeAllPoints()
        jointSegmentPath.removeAllPoints()

        // Add all joints and segments
        jointsOfInterest.forEach { point in
            let pointKey = point.rawValue
            guard let nextJoint = joints[pointKey] else {
                return
            }

            let nextJointScaled = nextJoint.applying(flipVertical).applying(scaleToBounds)
            let nextJointPath = UIBezierPath(arcCenter: nextJointScaled, radius: jointRadius,
                                             startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: true)
            jointPath.append(nextJointPath)
            if jointSegmentPath.isEmpty {
                jointSegmentPath.move(to: nextJointScaled)
            } else {
                if point == .bodyLandmarkKeyLeftWrist {
                    jointSegmentPath.move(to: nextJointScaled)
                } else {
                    jointSegmentPath.addLine(to: nextJointScaled)
                }
            }
        }

        DispatchQueue.main.async {
            self.jointLayer.path = self.jointPath.cgPath
            self.jointSegmentLayer.path = self.jointSegmentPath.cgPath
        }
    }
}
