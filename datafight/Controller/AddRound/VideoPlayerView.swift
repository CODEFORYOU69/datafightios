//
//  VideoPlayerView.swift
//  datafight
//
//  Created by younes ouasmi on 26/08/2024.
//

import AVFoundation
import UIKit

class VideoPlayerView: UIView {
    // MARK: - Properties
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayer()
    }

    // MARK: - Setup
    private func setupPlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer!)
    }

    // MARK: - Cleanup
    func cleanup() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }

    // MARK: - Video Loading
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
    }
}
