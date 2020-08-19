import UIKit

class ProgressBar: UIView {
    
    var fillImage: UIImage? {
        let inset =  UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 12)
        return UIImage(named: "progressBarLineFillRed")?.resizableImage(withCapInsets: inset, resizingMode: .stretch)
    }
    
    var backgroundTrackImage: UIImage? {
        return UIImage(named: "progressBarLineBackground")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2))
    }
    
    var view: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var progressImageView: UIImageView!
    
    @IBOutlet weak var progressConstraint: NSLayoutConstraint?
    
    fileprivate(set) var progress: Float = 0.0
    var progressValue: Float {
        return progress
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        view = loadViewFromNib()
        view.frame = bounds
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        backgroundColor = UIColor.clear
        setImages()
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ProgressBar", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func setImages() {
        /*
        backgroundImageView.image = backgroundTrackImage
        progressImageView.image = fillImage
         */
        backgroundImageView.image = nil
        progressImageView.image = nil
        backgroundImageView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        progressImageView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.8)
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateProgress()
    }
    
    func updateProgress(_ animated: Bool = false) {
        func update() {
            var height = CGFloat(progress) * frame.size.height
            height = min(height, frame.size.height)
            height = max(height, 0)
            if height.isFinite {
                self.progressConstraint?.constant = height
            }
            
            if animated {
                UIView.animate(withDuration: 0.3, animations: {  
                    self.layoutIfNeeded()
                })
            } else {
                self.layoutIfNeeded()
            }
        }
        
        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async {
                update()
            }
        }   
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        self.progress = progress
        updateProgress(animated)
        
        accessibilityLabel = "Progress Bar"
        accessibilityHint = "progress value \(String(format: "%.1f", progress))"
    }
}
