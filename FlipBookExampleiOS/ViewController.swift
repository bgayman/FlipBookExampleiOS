//
//  ViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/27/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit
import FlipBook
import AVKit
import PhotosUI

// MARK: - Constants -

let totalAnimationDuration: TimeInterval = 6.0

// MARK: - ViewController -

final class ViewController: UIViewController {
    
    enum Segment: Int {
        case video
        case livePhoto
        case gif
    }

    var redView: UIView?
    let flipBook = FlipBook()
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let redView = UIView(frame: CGRect(x: 50, y: 150, width: 100.0, height: 100.0))
        redView.backgroundColor = UIColor.systemRed
        containerView.addSubview(redView)
        self.redView = redView
        recordButton.layer.masksToBounds = true
        recordButton.layer.cornerRadius = 20.0
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.backgroundColor = UIColor.systemRed
    }
    
    @IBAction func record(_ sender: UIButton) {
        startRecording()
        animateView()
    }
    
    @IBAction func updateSegment(_ sender: UISegmentedControl) {
        guard let segment = Segment(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        switch segment {
        case .video:
            flipBook.preferredFramesPerSecond = 60
            flipBook.assetType = .video
        case .livePhoto:
            flipBook.preferredFramesPerSecond = 60
            flipBook.assetType = .livePhoto(nil)
        case .gif:
            flipBook.preferredFramesPerSecond = 12
            flipBook.assetType = .gif
        }
    }
    
    private func startRecording() {
        flipBook.startRecording(containerView, progress: { [weak self] (prog) in
            self?.progressView.progress = Float(prog)
        }, completion: { [weak self] result in
            switch result {
            case .success(let asset):
                switch asset {
                case .video(let url):
                    let videoVC = VideoViewController()
                    videoVC.videoURL = url
                    self?.navigationController?.pushViewController(videoVC, animated: true)
                case let .livePhoto(livePhoto, resources):
                    let livePhotoVC = LivePhotoViewController()
                    livePhotoVC.livePhoto = livePhoto
                    livePhotoVC.resources = resources
                    self?.navigationController?.pushViewController(livePhotoVC, animated: true)
                case .gif(let url):
                    let gifVC = GIFViewController()
                    gifVC.imageURL = url
                    self?.navigationController?.pushViewController(gifVC, animated: true)
                }
            case .failure(let error):
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                self?.present(alertController, animated: true)
            }
            self?.progressView.isHidden = true
            self?.progressView.progress = 0.0
        })
    }
    
    private func animateView() {
        let frame = redView?.frame ?? .zero
        UIView.animate(withDuration: totalAnimationDuration * 0.5, animations: {
            self.redView?.frame = CGRect.init(x: 0.0, y: self.containerView.frame.maxY - self.containerView.bounds.width, width: self.containerView.bounds.width, height: self.containerView.bounds.width)
        }, completion: { _ in
            UIView.animate(withDuration: totalAnimationDuration * 0.5, animations: {
                self.redView?.frame = frame
            }, completion: { _ in
                self.flipBook.stop()
                self.progressView.isHidden = false
            })
        })
    }
}

// MARK: - VideoViewController -

final class VideoViewController: UIViewController {
    
    var videoURL: URL?
    
    lazy private var avVC: AVPlayerViewController = AVPlayerViewController()
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
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
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let url = videoURL else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }
}

// MARK: - LivePhotoViewController -

final class LivePhotoViewController: UIViewController {
    
    let flipBookLivePhotoWriter = FlipBookLivePhotoWriter()
    var livePhoto: PHLivePhoto?
    var resources: LivePhotoResources?
    private var livePhotoView: PHLivePhotoView?
    
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Live Photo"
        navigationItem.prompt = "Long press to view movie"
        let livePhotoView = PHLivePhotoView(frame: view.bounds)
        livePhotoView.backgroundColor = UIColor.systemBlue
        self.livePhotoView = livePhotoView
        self.livePhotoView?.livePhoto = livePhoto
        view.addSubview(livePhotoView)
        
        navigationItem.rightBarButtonItem = shareBarButtonItem
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        livePhotoView?.frame = view.bounds
    }
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let resources = self.resources else {
            return
        }
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch status {
                case .notDetermined, .denied, .restricted:
                    break
                case .authorized:
                    let alert = UIAlertController(title: "Save", message: "Save Live Photo to Photo Library", preferredStyle: .alert)
                    let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
                        self.flipBookLivePhotoWriter.saveToLibrary(resources) { (result) in
                            switch result {
                            case .success:
                                print("Success")
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(saveAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true)
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - GIFViewController -

final class GIFViewController: UIViewController {
    
    var imageURL: URL?
    private var imageView: UIImageView?
    
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
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
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let url = imageURL else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }
}
