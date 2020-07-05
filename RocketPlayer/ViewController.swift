//
//  ViewController.swift
//  RocketPlayer
//
//  Created by Masato TSUTSUMI on 2020/07/04.
//  Copyright © 2020 Masato TSUTSUMI. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {
    
    var player: MPMusicPlayerController!
    var timer = Timer()
    var timeinterval = TimeInterval()
    var track: MPMediaItem!
    var currentTime = 0.0
    
    @IBOutlet weak var artworkContainerView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var needleImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = MPMusicPlayerController.applicationMusicPlayer
        player.beginGeneratingPlaybackNotifications()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(type(of: self).nowPlayingItemChanged(notification:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        
        self.playButton.imageView?.contentMode = .scaleAspectFit
        self.playButton.contentHorizontalAlignment = .fill
        self.playButton.contentVerticalAlignment = .fill
        self.artistNameLabel.textColor = .systemRed
        
        self.artworkContainerView.layer.cornerRadius = 150
        self.artworkContainerView.clipsToBounds = true
        
        self.needleImageView.image = UIImage(named: "needle")?.rotatedBy(degree: 30, isCropped: false)
        
        if let mediaItem = self.player.nowPlayingItem {
            self.updateTrack(mediaItem: mediaItem)
        } else {
            let picker = MPMediaPickerController()
            picker.delegate = self
            picker.allowsPickingMultipleItems = false
            present(picker, animated: true, completion: nil)
        }
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
        player.endGeneratingPlaybackNotifications()

    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        self.player.currentPlaybackTime = TimeInterval(self.slider.value)
        self.currentTime = self.player.currentPlaybackTime
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        switch self.player.playbackState {
        case .playing:
            self.player.pause()
            self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        default:
            self.player.play()
            self.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
    
    @IBAction func pickButtonTapped(_ sender: Any) {
        let picker = MPMediaPickerController()
        picker.delegate = self
        picker.allowsPickingMultipleItems = false
        
        timer.invalidate()
        player.pause()
        self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        player.stop()
        player.setQueue(with: mediaItemCollection)
        
        if let mediaitem = mediaItemCollection.items.first {
            updateTrack(mediaItem: mediaitem)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func nowPlayingItemChanged(notification: NSNotification) {
        if let playingitem = self.player.nowPlayingItem {
            updateTrack(mediaItem: playingitem)
        }
    }
    
    func updateTrack(mediaItem: MPMediaItem) {
        self.track = mediaItem
        self.artistNameLabel.text = mediaItem.albumArtist ?? "various artist"
        self.artworkImageView.image = mediaItem.artwork?.image(at: self.artworkImageView.bounds.size)
        self.trackNameLabel.text = mediaItem.title ?? "unknown title"
        self.timeinterval = mediaItem.playbackDuration
        self.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        self.startTime.text = "00:00"
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        let date = Date(timeIntervalSinceReferenceDate: timeinterval)
        self.endTime.text = formatter.string(from: date)
        self.player.play()
        self.slider.maximumValue = Float(timeinterval)
        self.timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }
        
    @objc func updateSlider() {
        let currentTime = self.player.currentPlaybackTime
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        let date = Date(timeIntervalSinceReferenceDate: currentTime)
        self.startTime.text = formatter.string(from: date)
        self.slider.setValue(Float(currentTime), animated: true)
        self.artworkImageView.image = self.track.artwork?.image(at: self.artworkImageView.bounds.size)?.rotatedBy(degree: CGFloat(currentTime * 100))
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
}

public extension CGFloat {
    
    func toRadians() -> CGFloat {
        return self / (180 * .pi)
    }
    
    func toDegrees() -> CGFloat {
        return self * (180 * .pi)
    }
}

public extension UIImage {
    func rotatedBy(degree: CGFloat, isCropped: Bool = true) -> UIImage {
        let radian = -degree * CGFloat.pi / 180
        var rotatedRect = CGRect(origin: .zero, size: self.size)
        if !isCropped {
            rotatedRect = rotatedRect.applying(CGAffineTransform(rotationAngle: radian))
        }
        UIGraphicsBeginImageContext(rotatedRect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: rotatedRect.size.width / 2, y: rotatedRect.size.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)

        context.rotate(by: radian)
        context.draw(self.cgImage!, in: CGRect(x: -(self.size.width / 2), y: -(self.size.height / 2), width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rotatedImage
    }
}
