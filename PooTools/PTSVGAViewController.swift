//
//  PTSVGAViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import CryptoKit
import SVGAPlayer

var cacheDirPath: String {
    NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, .userDomainMask, true).first ?? ""
}

func cacheFilePath(_ fileName: String) -> String {
    cacheDirPath + "/" + fileName
}

let LocalSources = [
    "Goddess",
    "heartbeat",
    cacheFilePath("Rocket.svga"),
    cacheFilePath("Rose.svga"),
]

let RemoteSources = [
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/EmptyState.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/HamburgerArrow.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/PinJump.svga?raw=true",
    "https://github.com/svga/SVGA-Samples/raw/master/Rocket.svga",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/TwitterHeart.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/Walkthrough.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/angel.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/halloween.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/kingset.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/posche.svga?raw=true",
    "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/rose.svga?raw=true",
]

class PTSVGAViewController: PTBaseViewController {

    let operationBar = UIView()
    let reverseSwitch = UISwitch()
    let player = SVGAPlayerSwiftEdition()
    let progressView = UIProgressView()
    
    var isProgressing: Bool = false {
        didSet {
            guard isProgressing != oldValue else { return }
            UIView.animate(withDuration: 0.15) {
                self.progressView.alpha = self.isProgressing ? 1 : 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .black
        
        setupOperationBar()
        setupPlayer()
        setupProgressView()
        
        writeBundleDataToCache("Rocket")
        writeBundleDataToCache("Rose")
        
        setupLoader()
        setupDownloader()
        setupCacheKeyGenerator()
    }
}

private extension PTSVGAViewController {
    // MARK: - 播放远程SVGA
    @objc func playRemote() {
        let svga = RemoteSources.randomElement()!
        player.play(svga)
    }

    // MARK: - 播放本地SVGA
    @objc func playLocal() {
        let svga = LocalSources.randomElement()!
        player.play(svga)
    }
    
    // MARK: - 反转播放
    @objc func toggleReverse(_ sender: UISwitch) {
        PTAlertTipControl.present(title:"Job Done!",subtitle: sender.isOn ? "开启反转播放" : "恢复正常播放",icon:.Done,style: .Normal)
        player.isReversing = sender.isOn
    }
    
    // MARK: - 播放
    @objc func play() {
        player.play()
    }
    
    // MARK: - 暂停
    @objc func pause() {
        player.pause()
    }
    
    // MARK: - 重新开始
    @objc func reset() {
        player.reset(isAutoPlay: true)
    }
    
    // MARK: - 停止
    @objc func stop() {
        player.stop()
    }
}

// MARK: - <SVGAPlayerSwiftEditionDelegate>
extension PTSVGAViewController: SVGAPlayerSwiftEditionDelegate {
    /// 状态发生改变【状态更新】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      statusDidChanged status: SVGAPlayerSwiftEditionStatus,
                      oldStatus: SVGAPlayerSwiftEditionStatus) {
        isProgressing = (status == .playing || status == .paused)
        switch status {
        case .loading:
            PTAlertTipControl.present(title:"",subtitle: "Loading",icon:.Heart,style: .SupportVisionOS)
            reverseSwitch.isUserInteractionEnabled = false
        default:
            PTAlertTipControl.present(title:"",subtitle: "Done",icon:.Done,style: .SupportVisionOS)
            reverseSwitch.isUserInteractionEnabled = true
        }
    }
    
    /// SVGA未知来源【无法播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      unknownSvga source: String) {
        PTAlertTipControl.present(title:"",subtitle: "未知来源",icon:.Error,style: .Normal)
    }
    
    /// SVGA资源加载失败【无法播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      dataLoadFailed error: Error) {
        PTAlertTipControl.present(title:"",subtitle: error.localizedDescription,icon:.Error,style: .Normal)

    }
    
    /// 加载的SVGA资源解析失败【无法播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      dataParseFailed error: Error) {
        PTAlertTipControl.present(title:"",subtitle: error.localizedDescription,icon:.Error,style: .Normal)
    }
    
    /// 本地SVGA资源解析失败【无法播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      assetParseFailed error: Error) {
        PTAlertTipControl.present(title:"",subtitle: error.localizedDescription,icon:.Error,style: .Normal)
    }
    
    /// SVGA资源无效【无法播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      entity: SVGAVideoEntity,
                      invalid error: SVGAVideoEntityError) {
        let status: String
        switch error {
        case .zeroVideoSize: status = "SVGA资源有问题：videoSize是0！"
        case .zeroFPS: status = "SVGA资源有问题：FPS是0！"
        case .zeroFrames: status = "SVGA资源有问题：frames是0！"
        default: return
        }
        PTAlertTipControl.present(title:"",subtitle: status,icon:.Error,style: .Normal)

    }
    
    /// SVGA动画执行回调【正在播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      animationPlaying currentFrame: Int) {
        guard player.isPlaying else { return }
        progressView.progress = Float(player.progress)
    }
    
    /// SVGA动画完成一次播放【正在播放】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition, svga source: String, animationDidFinishedOnce loopCount: Int) {
        PTNSLogConsole("完成第\(loopCount)次")
    }
    
    /// SVGA动画播放失败的回调【播放失败】
    func svgaPlayerSwiftEdition(_ player: SVGAPlayerSwiftEdition,
                      svga source: String,
                      animationPlayFailed error: SVGAPlayerPlayEditionError) {
        let status: String
        switch error {
        case .nullEntity: status = "SVGA资源是空的，无法播放"
        case .nullSuperview: status = "父视图是空的，无法播放"
        case .onlyOnePlayableFrame: status = "只有一帧可播放帧，无法形成动画"
        default: return
        }
        PTAlertTipControl.present(title:"",subtitle: status,icon:.Error,style: .Normal)
    }
}

// MARK: - Setup UI & Data
private extension PTSVGAViewController {
    func setupOperationBar() {
        view.addSubview(operationBar)
        operationBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarHeight_Total + CGFloat.kNavBarHeight)
        }
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = operationBar.bounds
        operationBar.addSubview(blurView)
        
        setupTopItems()
        setupBottomItems()
    }
    
    func setupTopItems() {
        let playRemoteBtn = UIButton(type: .system)
        playRemoteBtn.setTitle("Remote SVGA", for: .normal)
        playRemoteBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        playRemoteBtn.tintColor = .systemYellow
        playRemoteBtn.addTarget(self, action: #selector(playRemote), for: .touchUpInside)
        playRemoteBtn.sizeToFit()
        
        let playLocalBtn = UIButton(type: .system)
        playLocalBtn.setTitle("Local SVGA", for: .normal)
        playLocalBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        playLocalBtn.tintColor = .systemTeal
        playLocalBtn.addTarget(self, action: #selector(playLocal), for: .touchUpInside)
        playLocalBtn.sizeToFit()
        
        reverseSwitch.isOn = false
        reverseSwitch.addTarget(self, action: #selector(toggleReverse(_:)), for: .valueChanged)
        operationBar.addSubviews([playRemoteBtn,playLocalBtn,reverseSwitch])
        playRemoteBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalToSuperview()
            make.width.equalTo(playRemoteBtn.sizeFor().width)
        }
        
        playLocalBtn.snp.makeConstraints { make in
            make.left.equalTo(playRemoteBtn.snp.right).offset(20)
            make.height.top.equalTo(playRemoteBtn)
            make.width.equalTo(playLocalBtn.sizeFor().width)
        }

        reverseSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(34)
            make.top.equalToSuperview().inset(5)
        }
    }
    
    func setupBottomItems() {
        let stackView = UIStackView()
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        operationBar.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(reverseSwitch.snp.bottom).offset(5)
            make.height.equalTo(CGFloat.kTabbarHeight)
        }
        
        func createBtn(_ title: String, _ action: Selector) -> UIButton {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            btn.tintColor = .white
            btn.addTarget(self, action: action, for: .touchUpInside)
            btn.frame.size = CGSize(width: 60, height: CGFloat.kTabbarHeight)
            return btn
        }
        
        stackView.addArrangedSubview(
            createBtn("Play", #selector(play))
        )
        
        stackView.addArrangedSubview(
            createBtn("Pause", #selector(pause))
        )
        
        stackView.addArrangedSubview(
            createBtn("Reset", #selector(reset))
        )
        
        stackView.addArrangedSubview(
            createBtn("Stop", #selector(stop))
        )
    }
    
    func setupPlayer() {
        player.contentMode = .scaleAspectFit
        view.addSubview(player)
        player.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            make.bottom.equalTo(operationBar.snp.top)
        }
        
        player.isAnimated = true
        player.exDelegate = self
    }
    
    func setupProgressView() {
        progressView.trackTintColor = .clear
        progressView.alpha = 0
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(3)
            make.bottom.equalTo(operationBar.snp.top)
        }
    }
    
    func writeBundleDataToCache(_ resName: String) {
        guard let url = Bundle.main.url(forResource: resName, withExtension: "svga") else {
            PTNSLogConsole(resName, "路径不存在")
            return
        }
        
        let cacheUrl = URL(fileURLWithPath: cacheFilePath(resName + ".svga"))
        try? FileManager.default.removeItem(at: cacheUrl)
        
        do {
            let data = try Data(contentsOf: url)
            try data.write(to: cacheUrl)
        } catch {
            PTNSLogConsole(resName, "写入错误：", error)
        }
    }
}

// MARK: - Setup SVGA Loader & Downloader & CacheKeyGenerator
private extension PTSVGAViewController {
    func setupLoader() {
        SVGAPlayerSwiftEdition.loader = { svgaSource, success, failure, forwardDownload, forwardLoadAsset in
            guard FileManager.default.fileExists(atPath: svgaSource) else {
                if svgaSource.hasPrefix("http://") || svgaSource.hasPrefix("https://") {
                    forwardDownload(svgaSource)
                } else {
                    forwardLoadAsset(svgaSource)
                }
                return
            }
            
            PTNSLogConsole("加载磁盘的SVGA - \(svgaSource)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: svgaSource))
                success(data)
            } catch {
                failure(error)
            }
        }
    }
    
    func setupDownloader() {
        SVGAPlayerSwiftEdition.downloader = { svgaSource, success, failure in
            let _ = PTFileDownloadApi.init(fileUrl: svgaSource, saveFilePath: FileManager.pt.CachesDirectory() + "\(svgaSource.lastPathComponent)", progress: nil, success: { result in
                success(result.value!)
            }, fail: { error in
                failure(error!)
            })
        }
    }
    
    func setupCacheKeyGenerator() {
        SVGAPlayerSwiftEdition.cacheKeyGenerator = { $0.md5 }
    }
}
