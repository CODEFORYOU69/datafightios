//
//  VideoPlayerView.swift
//  datafight
//
//  Created by younes ouasmi on 26/08/2024.
//

import UIKit

import AVFoundation

class VideoPlayerView: UIView {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayer()
    }
    
    private func setupPlayer() {
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer!)
    }
    func cleanup() {
           player?.pause()
           player?.replaceCurrentItem(with: nil)
           player = nil
           playerLayer?.removeFromSuperlayer()
           playerLayer = nil
       }
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
    }
}
