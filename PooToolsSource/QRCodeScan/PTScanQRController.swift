//
//  PTViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
import SwifterSwift

public class PTScanBarInfo:PTBaseModel
{
    var codeView:UIView = UIView()
    var codeString:String = ""
}

@objcMembers
public class PTScanQRConfig:NSObject
{
    ///返回按鈕圖片
    var backImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    ///獲取相冊圖片
    var photoImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    ///電筒圖片
    var flashImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    var flashImageSelected:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    ///掃描線圖片
    var scanLineImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    ///點擊二維碼圖片
    var qrCodeImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    ///條形碼提示
    var barCodeTips:String = "掃描條形碼"
    ///取消按鈕名字
    var cancelButtonName:String = "取消"
    ///掃描二維碼後提示
    var scanedTips:String = "轻触小蓝点，选中识别二维码"
    ///是否可以掃二維碼
    var canScanQR:Bool = true
}

public typealias PTQRCodeResultBlock = (_ result:String) -> Void

@objcMembers
public class PTScanQRController: PTBaseViewController {

    //MARK: 掃描回調
    ///掃描回調
    public var resultBlock:PTQRCodeResultBlock?
    
    let scanningLineX:CGFloat = 0.5 * (1 - 0.9) * CGFloat.kSCREEN_WIDTH
    let scanningLineY:CGFloat = 0.25 * CGFloat.kSCREEN_HEIGHT
    let scanningLineW:CGFloat = 0.9 * CGFloat.kSCREEN_WIDTH
    let scanningLineH:CGFloat = 12

    ///掃描線動畫時間,默認0.02秒
    private lazy var animationTimeInterval:TimeInterval = 0.02
    private lazy var layerArr = [PTScanBarInfo]()
    private lazy var barCodes = [[String:Any]]()
    ///是否打開手電筒
    private var torchOn:Bool = false
    ///首次進入,addTimer那裏不執行startSession的操作,不然容易和初始化的start重複導致多次start
    private var hasEntered:Bool = true
    private var timer = Timer()
    ///處理掃描線動畫
    private var flag = true
    private var qrCode:Bool = true
    private var viewConfig:PTScanQRConfig = PTScanQRConfig()

    //MARK: AVKit
    lazy var videoPreviewLayer : AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = self.view.bounds
        return layer
    }()
    
    lazy var metadataOutput : AVCaptureMetadataOutput = {
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return output
    }()

    lazy var videoDataOutput : AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        return output
    }()
    
    lazy var session : AVCaptureSession = {
        let cSession = AVCaptureSession()
        cSession.sessionPreset = .hd1920x1080
        return cSession
    }()
    
    lazy var device:AVCaptureDevice = {
        let avDevice = AVCaptureDevice.default(for: .video)
        do
        {
            try avDevice?.lockForConfiguration()
            if avDevice!.isSmoothAutoFocusSupported
            {
                avDevice!.isSmoothAutoFocusEnabled = true
            }
            
            if avDevice!.isFocusModeSupported(.autoFocus)
            {
                avDevice!.focusMode = .autoFocus
            }
            
            if avDevice!.isExposureModeSupported(.continuousAutoExposure)
            {
                avDevice!.exposureMode = .continuousAutoExposure
            }
            
            if avDevice!.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)
            {
                avDevice!.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            avDevice!.unlockForConfiguration()
        }
        catch
        {
            PTNSLogConsole(error.localizedDescription)
        }
        return avDevice!
    }()
    
    //MARK: 按鈕
    lazy var backBtn : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.viewConfig.backImage, for: .normal)
        view.addActionHandlers { sender in
            if self.session.isRunning
            {
                self.session.stopRunning()
            }
            self.returnFrontVC()
        }
        return view
    }()
    
    lazy var photosButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.viewConfig.photoImage, for: .normal)
        view.addActionHandlers { sender in
            self.photosAction()
        }
        return view
    }()
    
    lazy var flashButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(self.viewConfig.flashImage, for: .normal)
        view.setImage(self.viewConfig.flashImageSelected, for: .selected)
        view.addActionHandlers { sender in
            self.torchOn = !self.torchOn
            if self.device.hasTorch
            {
                do
                {
                    try self.device.lockForConfiguration()
                    
                    if self.torchOn
                    {
                        self.device.torchMode = .on
                        sender.isSelected = true
                    }
                    else
                    {
                        self.device.torchMode = .off
                        sender.isSelected = false
                    }
                    self.device.unlockForConfiguration()
                }
                catch
                {
                    PTNSLogConsole(error.localizedDescription)
                }
            }
        }
        return view
    }()
    
    //MARK: Label
    lazy var tipsLabel : UILabel = {
        let view = UILabel()
        view.text = self.viewConfig.barCodeTips
        view.font = .appfont(size: 16,bold: true)
        view.textAlignment = .center
        view.textColor = .white
        view.backgroundColor = UIColor.colorBase(R: 54/255, G: 85/255, B: 230/255, A: 0.2)
        return view
    }()
    
    //MARK: 圖片
    lazy var scanningLine : UIImageView = {
        let view = UIImageView()
        view.image = self.viewConfig.scanLineImage
        return view
    }()

    //MARK: 生命週期
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.removeTimer()
    }
        
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: 初始化
    ///初始化
    public init(viewConfig:PTScanQRConfig) {
        super.init(nibName: nil, bundle: nil)
        self.viewConfig = viewConfig
        self.qrCode = self.viewConfig.canScanQR
        self.view.backgroundColor = .black
        
        var views = [UIView]()
        if self.device.hasTorch
        {
            views = [self.backBtn,self.photosButton,self.flashButton]
        }
        else
        {
            views = [self.backBtn,self.photosButton]
        }
        
        self.view.addSubviews(views)
        self.backBtn.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
        }
        
        self.photosButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalTo(self.backBtn)
            make.width.height.equalTo(self.backBtn)
        }
        
        if self.device.hasTorch
        {
            self.flashButton.snp.makeConstraints { make in
                make.width.height.equalTo(self.backBtn)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + CGFloat.ScaleW(w: 10))
            }
        }
        
        self.addTimer()
        self.startScanAction {
            self.scanSession()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: 進入相冊
    func enterPhotos()
    {
        PTGCDManager.gcdAfter(time: 0.1) {
            if #available(iOS 14.0, *)
            {
                Task{
                    do{
                        let object:PTAlbumObject = try await PTImagePicker.openAlbum()
                        await MainActor.run{
                            if let imageData = object.imageData,let image = UIImage(data: imageData)
                            {
                                self.findQR(inImage: image)
                            }
                            else
                            {
                                PTNSLogConsole("獲取圖片出現錯誤")
                            }
                        }
                    }
                    catch let pickerError as PTImagePicker.PickerError
                    {
                        pickerError.outPutLog()
                    }
                }
            }
            else
            {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                imagePicker.modalPresentationStyle = .fullScreen
                self.present(imagePicker, animated: true)
            }
        }
    }
    
    //MARK: 點擊相冊按鈕動作
    func photosAction()
    {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined
        {
            PHPhotoLibrary.requestAuthorization { blockStatus in
                if blockStatus == .authorized
                {
                    PTGCDManager.gcdMain {
                        self.enterPhotos()
                    }
                }
            }
        }
        else if status == .authorized
        {
            self.enterPhotos()
        }
        else if status == .denied
        {
            let messageString = "[前往：设置 - 隐私 - 照片 - \(kAppName!)] 允许应用访问"
            UIAlertController.alertVC(title:"溫馨提示",msg: messageString,cancel: "好的") {
                
            }
        }
        else
        {
            UIAlertController.alertVC(title:"溫馨提示",msg: "由于系统原因, 无法访问相册",cancel: "好的") {
                
            }
        }
    }
    
    //MARK: 檢測相機模塊
    func startScanAction(handle:@escaping (()->Void))
    {
        let device = AVCaptureDevice.default(for: .video)
        if device != nil
        {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if authStatus == .restricted
            {
                UIAlertController.alertVC(title:"溫馨提示",msg: "由于系统原因, 无法访问相机",cancel: "好的") {
                    self.returnFrontVC()
                }
            }
            else if authStatus == .denied
            {
                let messageString = "[前往：设置 - 相机 - 照片 - \(kAppName!)] 允许应用访问"
                UIAlertController.alertVC(title:"溫馨提示",msg: messageString,cancel: "好的") {
                    self.returnFrontVC()
                }
            }
            else if authStatus == .authorized
            {
                handle()
            }
            else if authStatus == .notDetermined
            {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted
                    {
                        PTGCDManager.gcdMain {
                            handle()
                        }
                    }
                    else
                    {
                        self.processResult(result: "用戶拒絕使用相機")
                    }
                }
            }
            else
            {
                self.processResult(result: "未檢測到攝像頭,要在真機上測試")
            }
        }
    }
    
    //MARK: 開始掃描
    func scanSession()
    {
        do
        {
            let deviceInput = try AVCaptureDeviceInput.init(device: self.device)
            self.session.addOutput(self.metadataOutput)
            self.session.addOutput(self.videoDataOutput)
            self.session.addInput(deviceInput)
            
            if self.qrCode
            {
                self.metadataOutput.metadataObjectTypes = [.qr,.ean13,.ean8,.code128]
            }
            else
            {
                self.metadataOutput.metadataObjectTypes = [.ean13,.ean8,.code128]
            }
            
            self.view.layer.insertSublayer(self.videoPreviewLayer, at: 0)
            PTGCDManager.gcdBackground {
                self.session.startRunning()
            }
            
            if !self.qrCode
            {
                self.view.addSubview(self.tipsLabel)
                self.tipsLabel.snp.makeConstraints { make in
                    make.left.equalTo(self.backBtn.snp.right)
                    make.right.equalTo(self.photosButton.snp.left)
                    make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                }
            }
        }
        catch
        {
            PTNSLogConsole(error.localizedDescription)
        }
    }
    
    //MARK: 添加時間控制器
    func addTimer()
    {
        if !self.session.isRunning && self.hasEntered
        {
            PTGCDManager.gcdBackground {
                self.session.startRunning()
            }
        }
        self.hasEntered = false
        
        self.view.addSubview(self.scanningLine)
        self.scanningLine.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(self.scanningLineX)
            make.top.equalToSuperview().inset(self.scanningLineY)
            make.width.equalTo(self.scanningLineW)
            make.height.equalTo(self.scanningLineH)
        }
        self.timer = Timer(timeInterval: self.animationTimeInterval, target: self, selector: #selector(self.beginRefreshUI), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer, forMode: .common)
    }
    
    //MARK: 移除時間控制器
    func removeTimer()
    {
        self.timer.invalidate()
        self.scanningLine.removeFromSuperview()
        if self.session.isRunning
        {
            self.session.stopRunning()
        }
    }
    
    //MARK: 刷新掃描線動畫
    func beginRefreshUI()
    {
        if !self.session.isRunning
        {
            self.removeTimer()
        }

        var frame = self.scanningLine.frame
        if self.flag
        {
            frame.origin.y = self.scanningLineY
            self.flag = false
            UIView.animate(withDuration: self.animationTimeInterval) {
                frame.origin.y += 2
                self.scanningLine.frame = frame
            }
        }
        else
        {
            if self.scanningLine.origin.y >= self.scanningLineY
            {
                let scanContentMaxY = self.view.frame.size.height - self.scanningLineY
                if self.scanningLine.frame.origin.y >= scanContentMaxY - 10
                {
                    frame.origin.y = self.scanningLineY
                    self.scanningLine.frame = frame
                    self.flag = false
                }
                else
                {
                    UIView.animate(withDuration: self.animationTimeInterval) {
                        frame.origin.y += 2
                        self.scanningLine.frame = frame
                    }
                }
            }
            else
            {
                self.flag = !self.flag
            }
        }
    }
    
    //MARK: 獲取二維碼數據後處理回調
    func processResult(result:String)
    {
        PTNSLogConsole(result)
        if self.resultBlock != nil
        {
            self.resultBlock!(result)
        }
        self.returnFrontVC()
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    //MARK: 根據UIImage來查找QR code
    func findQR(inImage image:UIImage)
    {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil,options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        let features = detector?.features(in: CIImage(cgImage: image.cgImage!))
        if features!.count == 0
        {
            self.processResult(result: "無法查找二維碼")
        }
        else
        {
            let feature:CIQRCodeFeature = features![0] as! CIQRCodeFeature
            let resultString = feature.messageString
            self.processResult(result: resultString!)
        }
    }
}

extension PTScanQRController:UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.returnFrontVC()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image:UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        self.findQR(inImage: image)
    }
}

extension PTScanQRController:AVCaptureMetadataOutputObjectsDelegate
{
    func showMaskView(showTips:Bool)->UIView
    {
        let maskView = UIView(frame: self.view.bounds)
        maskView.backgroundColor = UIColor.colorBase(R: 0, G: 0, B: 0, A: 0.6)
        if showTips
        {
            let cancel = UIButton(type: .custom)
            cancel.setTitleColor(.white, for: .normal)
            cancel.setTitle(self.viewConfig.cancelButtonName, for: .normal)
            cancel.addActionHandlers { sender in
                if self.session.isRunning
                {
                    self.session.stopRunning()
                }
                self.layerArr.enumerated().forEach { index,value in
                    value.codeView.removeFromSuperview()
                }
                self.layerArr.removeAll()
                if !self.session.isRunning
                {
                    self.hasEntered = true
                    self.addTimer()
                }
                self.backBtn.isHidden = false
            }
            maskView.addSubview(cancel)
            cancel.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(44)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            }
            
            let tipsLabel = UILabel()
            tipsLabel.text = self.viewConfig.scanedTips
            tipsLabel.font = .appfont(size: 14,bold: true)
            tipsLabel.textAlignment = .center
            tipsLabel.textColor = .white
            maskView.addSubview(tipsLabel)
            tipsLabel.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalToSuperview().inset(CGFloat.kTabbarHeight_Total)
            }
        }
        return maskView
    }
    
    func showCodeButton(bounds:CGRect,icon:Bool)->UIButton
    {
        let btn = UIButton(type: .custom)
        btn.frame = bounds
        btn.backgroundColor = UIColor.colorBase(R: 54/255, G: 85/255, B: 230/255, A: 1)
        btn.addActionHandlers { sender in
            let barinfo = self.layerArr[sender.tag]
            self.processResult(result: barinfo.codeString)
        }
        
        if icon
        {
            btn.setImage(self.viewConfig.qrCodeImage, for: .normal)
            btn.layer.add(self.btnAnimation(), forKey: "scale-layer")
        }
        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.borderWidth = 3
        return btn
    }
    
    func btnAnimation()->CAKeyframeAnimation
    {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.duration = 2.8
        animation.isRemovedOnCompletion = false
        animation.repeatCount = Float.infinity
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        let value = NSNumber(floatLiteral: 1)
        let value2 = NSNumber(floatLiteral: 0.8)
        animation.values = [value,value2,value,value2,value,value,value,value]
        return animation
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0
        {
            self.removeTimer()
            
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
        }
        
        AudioServicesPlaySystemSound(1108)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        let maskView = self.showMaskView(showTips: (metadataObjects.count > 1))
        maskView.alpha = 0
        self.view.addSubview(maskView)
        UIView.animate(withDuration: 0.6) {
            maskView.alpha = 1
        }
        
        let barInfo = PTScanBarInfo()
        barInfo.codeView = maskView
        barInfo.codeString = ""
        self.layerArr.append(barInfo)
        
        metadataObjects.enumerated().forEach { index,value in
            let code:AVMetadataMachineReadableCodeObject = self.videoPreviewLayer.transformedMetadataObject(for: value) as! AVMetadataMachineReadableCodeObject
            let codeBtn = self.showCodeButton(bounds: code.bounds, icon: (metadataObjects.count > 1))
            codeBtn.tag = index + 1
            self.view.addSubview(codeBtn)
            
            let barInfo = PTScanBarInfo()
            barInfo.codeView = codeBtn
            barInfo.codeString = code.stringValue ?? ""
            self.layerArr.append(barInfo)
        }
        
        self.backBtn.isHidden = true
        if metadataObjects.count == 1
        {
            PTGCDManager.gcdAfter(time: 0.8) {
                let barInfo = self.layerArr[1]
                self.processResult(result: barInfo.codeString)
            }
        }
    }
}

extension PTScanQRController:AVCaptureVideoDataOutputSampleBufferDelegate
{
    
}
