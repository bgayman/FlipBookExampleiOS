//
//  GIFViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit
import FlipBook

// MARK: - GIFViewController -

final class GIFViewController: UIViewController {
    
    // MARK: - Properties -
    
    var imageURL: URL?
    private var imageView: UIImageView?
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    lazy private var gifWriter: FlipBookGIFWriter? = {
        do {
            var cachesDirectory: URL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            cachesDirectory.appendPathComponent("FlipBookGIF.gif")
            return FlipBookGIFWriter(fileOutputURL: cachesDirectory)
        } catch {
            return nil
        }
    }()
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GIF"
        let imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
        view.addSubview(imageView)
        guard let url = imageURL,
              let gifWriter = self.gifWriter,
              let images = gifWriter.makeImages(url),
              let frameRate = gifWriter.makeFrameRate(url) else {
                return
        }
        imageView.animationImages = images
        imageView.animationDuration = Double(images.count) / Double(frameRate)
        imageView.startAnimating()
        
        navigationItem.rightBarButtonItem = shareBarButtonItem
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView?.frame = view.bounds
    }
    
    // MARK: - Action -
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let url = imageURL else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }
}
