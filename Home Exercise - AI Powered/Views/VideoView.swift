//
//  VideoView.swift
//  Home Exercise - AI Powered
//
//  Created by Artem Sherbachuk on 8/19/20.
//

import AVFoundation
import UIKit

final class VideoView: UIView {

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!

    let playerLayer = AVPlayerLayer()

    deinit {
        if let currentItem = playerLayer.player?.currentItem {
            NotificationCenter.default.removeObserver(currentItem)
        }
    }

    var player: AVPlayer? {
        didSet {
            setup(for: player)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.addSublayer(playerLayer)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }


    private func setup(for player: AVPlayer?) {
        if let oldPlayer = playerLayer.player?.currentItem {
            NotificationCenter.default.removeObserver(oldPlayer)
        }

        playerLayer.player = player

        playerLayer.player?.play()

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: playerLayer.player?.currentItem,
                                               queue: .main) { [weak self] _ in
            self?.playerLayer.player?.seek(to: CMTime.zero)
            self?.playerLayer.player?.play()
        }
    }
}
