//
//  GIFViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit

// MARK: - GIFViewController -

final class GIFViewController: UIViewController {
    
    // MARK: - Properties -
    
    var imageURL: URL?
    private var imageView: UIImageView?
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GIF"
        let imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .scaleAspectFit
        self.imageView = imageView
        view.addSubview(imageView)
        guard let url = imageURL,
              let gifData = try? Data(contentsOf: url),
              let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        imageView.animationImages = images
        imageView.animationDuration = totalAnimationDuration
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
