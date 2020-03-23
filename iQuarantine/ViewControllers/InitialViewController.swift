//
//  ViewController.swift
//  iQuarantine
//
//  Created by Jonathan Kim on 3/22/20.
//  Copyright © 2020 nomadjonno. All rights reserved.
//

import UIKit
import AVKit

class InitialViewController: UIViewController {

    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    var videoPlayer: AVPlayer?
    var videoPlayerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupVideo()
    }
    
    private func setupVideo() {
        let bundlePath = Bundle.main.path(forResource: "loginbg", ofType: "mp4")        
        guard let path = bundlePath else { return }
        
        let url = URL(fileURLWithPath: path)
        let item = AVPlayerItem(url: url)
        
        videoPlayer = AVPlayer(playerItem: item)
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        
        videoPlayerLayer?.frame = CGRect(x: -view.frame.size.width * 1.5,
                                         y: 0,
                                         width: view.frame.size.width * 4,
                                         height: view.frame.size.height)
        view.layer.insertSublayer(videoPlayerLayer ?? AVPlayerLayer(), at: 0)
        videoPlayer?.playImmediately(atRate: 0.6)
        loopVideo(videoPlayer: videoPlayer ?? AVPlayer())
    }
    
    private func loopVideo(videoPlayer: AVPlayer) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { notification in
            self.videoPlayer?.seek(to: CMTime.zero)
            self.videoPlayer?.playImmediately(atRate: 0.6)
        }
    }
    
    private func setupUI() {
        Utilities.styleFilledButton(signUpButton)
        Utilities.styleHollowButton(loginButton)
    }
}

