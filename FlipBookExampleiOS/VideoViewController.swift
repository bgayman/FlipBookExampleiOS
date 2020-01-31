//
//  VideoViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit
import AVKit

// MARK: - VideoViewController -

final class VideoViewController: UIViewController {
    
    // MARK: - Properties -

    var videoURL: URL?
    lazy private var avVC: AVPlayerViewController = AVPlayerViewController()
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = videoURL else {
            return
        }
        let player = AVPlayer(url: url)
        avVC.view.frame = view.safeAreaLayoutGuide.layoutFrame
        avVC.player = player
        addChild(avVC)
        view.addSubview(avVC.view)
        avVC.didMove(toParent: self)
        navigationItem.rightBarButtonItem = shareBarButtonItem
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avVC.view.frame = view.safeAreaLayoutGuide.layoutFrame
    }
    
    // MARK: - Actions -
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let url = videoURL else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }
}
