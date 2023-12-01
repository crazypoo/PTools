//
//  PTFilterCameraViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Harbeth
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTFilterCameraViewController: PTBaseViewController {

    lazy var originImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .black
        imageView.frame = self.view.frame
        return imageView
    }()
    
    lazy var camera: C7CollectorCamera = {
        let camera = C7CollectorCamera.init(delegate: self)
        camera.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
//        camera.filters = [self.tuple!.filter]
        return camera
    }()
    
    //MARK: 生命週期
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColor = .clear
        self.zx_hideBaseNavBar = true
#else
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.view.backgroundColor = .clear
#endif

    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColor = .clear
        self.zx_hideBaseNavBar = true
#else
        navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.view.backgroundColor = .clear
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        camera.startRunning()
    }
    
    func setupUI() {
        view.backgroundColor = UIColor.background
        view.addSubview(originImageView)
    }
}

extension PTFilterCameraViewController: C7CollectorImageDelegate {
    
    func preview(_ collector: C7Collector, fliter image: C7Image) {
        self.originImageView.image = image
    }
    
    func captureOutput(_ collector: C7Collector, pixelBuffer: CVPixelBuffer) {
        
    }
    
    func captureOutput(_ collector: C7Collector, texture: MTLTexture) {
        
    }
}
