//
//  ViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/27/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit
import FlipBook
import AVFoundation

// MARK: - Constants -

let totalAnimationDuration: TimeInterval = 6.0

// MARK: - ViewController -

final class ViewController: UIViewController {
    
    
    // MARK: - Types -

    enum Segment: Int {
        case video
        case livePhoto
        case gif
    }

    // MARK: - Properties -

    var redView: UIView?
    let flipBook = FlipBook()
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var layerSwitch: UISwitch!
    @IBOutlet weak var layerContainerView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var layerOverlayView: UIView!
    
    var shouldCompositeLayerAnimation = false {
        didSet {
            containerView.isHidden = shouldCompositeLayerAnimation
            layerContainerView.isHidden = !shouldCompositeLayerAnimation
            layerOverlayView.isHidden = !shouldCompositeLayerAnimation
        }
    }
    
    // MARK: - Lifecycle -

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
        
        cardView.layer.cornerRadius = 20.0
        cardView.layer.shadowOpacity = 0.5
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        cardView.layer.shadowRadius = 5.0
    }
    
    // MARK: - Actions -

    @IBAction func record(_ sender: UIButton) {
        sender.isEnabled = false
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
    
    @IBAction func switchLayerAnimation(_ sender: UISwitch) {
        shouldCompositeLayerAnimation = sender.isOn
    }
    
    // MARK: - Private Methods -

    private func startRecording() {
        let sourceView: UIView = shouldCompositeLayerAnimation ? layerContainerView : containerView
        let composition: (CALayer) -> Void = { [weak self] layer in
            self?.animateLayer(in: layer, for: true)
        }
        flipBook.startRecording(sourceView,
                                compositionAnimation: shouldCompositeLayerAnimation ? composition : nil ,
                                progress: { [weak self] (prog) in
                                    self?.progressView.progress = Float(prog)
            },
                                completion: { [weak self] result in
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
                                    self?.recordButton.isEnabled = true
        })
    }
    
    private func animateView() {
        if shouldCompositeLayerAnimation {
            animateLayer(in: layerOverlayView.layer, for: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationDuration) {
                self.flipBook.stop()
                self.progressView.isHidden = false
            }
        } else {
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
    
    private func animateLayer(in layer: CALayer, for isForVideo: Bool) {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        let scale = isForVideo ? view.window?.screen.scale ?? 1.0 : 1.0

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = layer.bounds
        gradientLayer.colors = [UIColor.systemBlue.cgColor, UIColor.systemRed.cgColor]
        gradientLayer.isGeometryFlipped = isForVideo
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = layer.bounds
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 10.0 * scale
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        
        let cardViewRect = layerContainerView.convert(cardView.bounds, from: cardView)
        let insetRect = cardViewRect.insetBy(dx: 40.0, dy: 40.0)
        let pathRect = CGRect(x: insetRect.origin.x * scale,
                              y: insetRect.origin.y * scale,
                              width: insetRect.size.width * scale,
                              height: insetRect.size.height * scale)
        let path = UIBezierPath(ovalIn: pathRect)
        shapeLayer.path = path.cgPath
        
        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.duration = totalAnimationDuration
        strokeAnimation.fromValue = 0.0
        strokeAnimation.toValue = 1.0
        if isForVideo {
            strokeAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        }
        shapeLayer.add(strokeAnimation, forKey:"strokeAnimation")
    }
}
