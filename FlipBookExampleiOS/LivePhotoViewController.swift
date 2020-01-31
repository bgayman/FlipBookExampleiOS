//
//  LivePhotoViewController.swift
//  FlipBookExampleiOS
//
//  Created by Brad Gayman on 1/31/20.
//  Copyright © 2020 Brad Gayman. All rights reserved.
//

import UIKit
import PhotosUI
import FlipBook

// MARK: - LivePhotoViewController -

final class LivePhotoViewController: UIViewController {
    
    // MARK: - Properties -
    
    let flipBookLivePhotoWriter = FlipBookLivePhotoWriter()
    var livePhoto: PHLivePhoto?
    var resources: LivePhotoResources?
    private var livePhotoView: PHLivePhotoView?
    lazy private var shareBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share(_:)))
    
    // MARK: - Lifecycle -
    
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
    
    // MARK: - Actions -
    
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
