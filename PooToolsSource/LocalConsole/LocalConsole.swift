//
//  LocalConsole.swift
//  Diou
//
//  Created by jax on 2021/8/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import DeviceKit
import CoreFoundation

public let LocalConsoleFontBaseSize:CGFloat = 7.5
public let LocalConsoleFontMin:CGFloat = 4
public let LocalConsoleFontMax:CGFloat = 20
public let SystemLogViewTag = 999999
public let systemLog_base_width:CGFloat = 228
public let systemLog_base_height:CGFloat = 142
public let borderLine:CGFloat = 5
public let diameter:CGFloat = 28

public var App_UI_Debug_Bool:Bool
{
    let userDefaults = UserDefaults.standard.value(forKey: LocalConsole.ConsoleDebug)
    let ui_debug:Bool = userDefaults == nil ? false : (userDefaults as! Bool)
    return ui_debug
}

class ConsoleWindow: UIWindow {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let hitView = super.hitTest(point, with: event) {
            return hitView.isKind(of: ConsoleWindow.self) ? nil : hitView
        }
        return super.hitTest(point, with: event)
    }
}

@objc public enum LocalConsoleActionType : Int {
    case CopyLog
    case ShareLog
    case RestoreUserDefult
    case AppUpdate
    case Debug
    case DebugSetting
    case NoActionCallBack
}

public typealias PTLocalConsoleBlock = (_ actionType:LocalConsoleActionType,_ debug:Bool,_ logUrl:URL)->Void

@objcMembers
public class LocalConsole: NSObject {
    public static let shared = LocalConsole()
    
    public static let ConsoleDebug = "UI_debug"
    
    public var consoleActionBlock:PTLocalConsoleBlock?
    
    public var terminal:PTTerminal?
    var currentText: String = "" {
        didSet {
            DispatchQueue.main.async {
                self.setLog()
            }
        }
    }
    private var debugBordersEnabled = false {
        didSet {
            
            UIView.swizzleDebugBehaviour_UNTRACKABLE_TOGGLE()
            
            guard debugBordersEnabled else {
                GLOBAL_BORDER_TRACKERS.forEach {
                    $0.deactivate()
                }
                GLOBAL_BORDER_TRACKERS = []
                return
            }
            
            func subviewsRecursive(in _view: UIView) -> [UIView] {
                _view.subviews + _view.subviews.flatMap {
                    subviewsRecursive(in: $0)
                }
            }
            
            var allViews: [UIView] = []
            
            for window in UIApplication.shared.windows {
                allViews.append(contentsOf: subviewsRecursive(in: window))
            }
            allViews.forEach {
                let tracker = BorderManager(view: $0)
                GLOBAL_BORDER_TRACKERS.append(tracker)
                tracker.activate()
            }
        }
    }

    static let CopyKey : String = NSLocalizedString("复制当前Log", comment: "")
    static let ShareKey : String = NSLocalizedString("分享当前Log", comment: "")
    static let ResizeKey : String = NSLocalizedString("设置视窗大小", comment: "")
    static let RespringKey : String = NSLocalizedString("重启手机界面", comment: "")
    static let CleanKey : String = NSLocalizedString("清除输出", comment: "")
    static let ViewFrameKey : String = NSLocalizedString("显示界面的布局", comment: "")
    static let SystemReportKey : String = NSLocalizedString("系统信息", comment: "")
    static let RestoreFirstKey : String = NSLocalizedString("重置UserDefult", comment: "")
    static let AppUpdateKey : String = NSLocalizedString("应用更新", comment: "")
    static let DEBUGKey : String = NSLocalizedString("调试模式", comment: "")
    static let NORMALKey : String = NSLocalizedString("正常模式", comment: "")
    static let DEBUGSETTINGKey : String = NSLocalizedString("调试设置", comment: "")
    
    var popoverTitles : [String] = {
        var baseArr = [
            LocalConsole.CopyKey,
            LocalConsole.ShareKey,
            LocalConsole.ResizeKey,
            LocalConsole.RespringKey,
            LocalConsole.CleanKey,
            LocalConsole.ViewFrameKey,
            LocalConsole.SystemReportKey,
            LocalConsole.RestoreFirstKey,
            LocalConsole.AppUpdateKey,
            App_UI_Debug_Bool ? LocalConsole.DEBUGKey : LocalConsole.NORMALKey,
            LocalConsole.DEBUGSETTINGKey
        ]
        return baseArr
    }()

    private override init()
    {
        super.init()
    }
    
    public func cleanSystemLogView()
    {
        terminal?.removeFromSuperview()
        terminal = nil
        terminal?.systemIsVisible = false
    }
    
    func setLog()
    {
        if terminal!.systemText!.contentOffset.y > terminal!.systemText!.contentSize.height - terminal!.systemText!.bounds.size.height - 20
        {
            terminal!.systemText?.pendingOffsetChange = true
        }
        
        terminal!.systemText?.text = currentText
        terminal!.setAttributedText(currentText)
        terminal!.systemText!.contentOffset.y = terminal!.systemText!.contentSize.height
    }
        
    public func createSystemLogView()
    {
        if terminal == nil
        {
            terminal = PTTerminal.init(view: AppWindows!, frame: CGRect.init(x: 0, y: kNavBarHeight_Total, width: systemLog_base_width, height: systemLog_base_height))
            terminal?.tag = SystemLogViewTag
            terminal!.menuButton.addActionHandlers { sender in
                let actionSheet = PTActionSheetView.init(title: "调试功能", destructiveButton: "关闭",otherButtonTitles: self.popoverTitles,dismissWithTapBG: false)
                actionSheet.show()
                actionSheet.actionSheetSelectBlock = { (sheet,index) in
                    switch index {
                    case PTActionSheetView.DestructiveButtonTag:
                        self.cleanSystemLogView()
                    case PTActionSheetView.CancelButtonTag:
                        break
                    default:
                        self.popoverDidselect(dataName: self.popoverTitles[index])
                    }
                }
            }
        }
    }
    
    func popoverDidselect(dataName:String)
    {
        if dataName == LocalConsole.CopyKey
        {
            currentText.copyToPasteboard()
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.CopyLog,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.ShareKey
        {
            DOGobalFileManager.createLogFilePath()

            let fileName = "log.txt"

            let manager = FileManager.default
            let file = DOGobalFileManager.gobalLogFileURL().appendingPathComponent(fileName)
            let data = currentText.data(using: .utf8)
                                    
            if !DOGobalFileManager.isFileExist(fileName, withFilePath: DOGobalFileManager.gobalLogFileURL())
            {
                manager.createFile(atPath: file, contents: data, attributes: nil)
            }
            else
            {
                _ = manager.subpaths(atPath: DOGobalFileManager.gobalLogFileURL())
                try? manager.removeItem(at: URL.init(string: "file:///" + DOGobalFileManager.gobalLogFileURL())!)
                manager.createFile(atPath: file, contents: data, attributes: nil)
            }
            
            PTUtils.gcdAfter(time: 0.35) {
                let shareURL = URL.init(fileURLWithPath: "file:///" + DOGobalFileManager.gobalLogFileURL() + fileName)
                if self.consoleActionBlock != nil
                {
                    self.consoleActionBlock!(.ShareLog,false,shareURL)
                }
            }
        }
        else if dataName == LocalConsole.ResizeKey
        {
            ResizeController.shared.isActive.toggle()
            ResizeController.shared.platterView.reveal()
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.NoActionCallBack,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.RespringKey
        {
            guard let window = UIApplication.shared.windows.first else { return }
            
            window.layer.cornerRadius = UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat
            window.layer.masksToBounds = true
            
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
                window.transform = .init(scaleX: 0.96, y: 0.96)
                window.alpha = 0
            }
            animator.addCompletion { _ in
                while true {
                    window.snapshotView(afterScreenUpdates: false)
                }
            }
            animator.startAnimation()
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.NoActionCallBack,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.CleanKey
        {
            currentText = ""
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.NoActionCallBack,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.ViewFrameKey
        {
            debugBordersEnabled.toggle()
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.NoActionCallBack,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.SystemReportKey
        {
            var volumeAvailableCapacityForImportantUsageString = ""
            var volumeAvailableCapacityForOpportunisticUsageString = ""
            var volumesString = ""
            if #available(iOS 11.0, *)
            {
                volumeAvailableCapacityForImportantUsageString = String.init(format: "%d", Device.volumeAvailableCapacityForImportantUsage!)
                volumeAvailableCapacityForOpportunisticUsageString = String.init(format: "%d", Device.volumeAvailableCapacityForOpportunisticUsage!)
                volumesString = String.init(format: "%d", Device.volumes!)
            }
            else
            {
                volumeAvailableCapacityForImportantUsageString = "Not Support"
                volumeAvailableCapacityForOpportunisticUsageString = "Not Support"
                volumesString = "Not Support"
            }
            
            var hzString = ""
            if #available(iOS 10.3, *)
            {
                hzString = "MaxFrameRate: \(UIScreen.main.maximumFramesPerSecond) Hz"
            }
            
            var supportApplePencilString = ""
            switch UIDevice.pt.supportApplePencil {
            case .Both:
                supportApplePencilString = "Support All"
            case .Second:
                supportApplePencilString = "Only Support Second"
            case .First:
                supportApplePencilString = "Only Support First"
            case .BothNot:
                supportApplePencilString = "Both Not Support"
            }
            
            currentText = """
                    ModelName: \(SystemReport.shared.gestaltMarketingName)
                    ModelIdentifier: \(SystemReport.shared.gestaltModelIdentifier)
                    Architecture: \(SystemReport.shared.gestaltArchitecture)
                    Firmware: \(SystemReport.shared.gestaltFirmwareVersion)
                    KernelVersion: \(SystemReport.shared.kernel) \(SystemReport.shared.kernelVersion)
                    SystemVersion: \(SystemReport.shared.versionString)
                    OSCompileDate: \(SystemReport.shared.compileDate)
                    Memory: \(UIDevice.pt.memoryTotal) GB
                    ProcessorCores: \(Int(UIDevice.pt.processorCount))
                    ThermalState: \(SystemReport.shared.thermalState)
                    SystemUptime: \(UIDevice.pt.systemUptime)
                    LowPowerMode: \(UIDevice.pt.lowPowerMode)
                    IsSimulator: \(Device.current.isSimulator ? "Yes" : "No")
                    IsTouchIDCapable: \(Device.current.isTouchIDCapable ? "Yes" : "No")
                    IsFaceIDCapable: \(Device.current.isFaceIDCapable ? "Yes" : "No")
                    HasBiometricSensor:\(Device.current.hasBiometricSensor ? "Yes" : "No")
                    HasSensorHousing: \(Device.current.hasSensorHousing ? "Yes" : "No")
                    HasRoundedDisplayCorners: \(Device.current.hasRoundedDisplayCorners ? "Yes" : "No")
                    Has3dTouchSupport: \(Device.current.has3dTouchSupport ? "Yes" : "No")
                    SupportsWirelessCharging: \(Device.current.supportsWirelessCharging ? "Yes" : "No")
                    HasLidarSensor: \(Device.current.hasLidarSensor ? "Yes" : "No")
                    PPI: \(Device.current.ppi ?? 0)
                    ScreenSize: \(UIScreen.main.bounds.size)
                    ScreenCornerRadius: \(UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat)
                    ScreenScale: \(UIScreen.main.scale)
                    \(hzString)
                    Brightness: \(String(format: "%.2f", UIDevice.pt.brightness))
                    IsGuidedAccessSessionActive: \(Device.current.isGuidedAccessSessionActive ? "Yes" : "No")
                    BatteryState: \(Device.current.batteryState!)
                    BatteryLevel: \(String.init(format: "%d", Device.current.batteryLevel!))
                    VolumeTotalCapacity: \(String.init(format: "%d", Device.volumeTotalCapacity!))
                    VolumeAvailableCapacity: \(String.init(format: "%d", Device.volumeAvailableCapacity!))
                    VolumeAvailableCapacityForImportantUsage: \(volumeAvailableCapacityForImportantUsageString)
                    VolumeAvailableCapacityForOpportunisticUsage: \(volumeAvailableCapacityForOpportunisticUsageString)
                    Volumes: \(volumesString)
                    ApplePencilSupport: \(String.init(format: "%@", supportApplePencilString))
                    HasCamera: \(Device.current.hasCamera ? "Yes" : "No")
                    HasNormalCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                    HasWideCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                    HasTelephotoCamera: \(Device.current.hasTelephotoCamera ? "Yes" : "No")
                    HasUltraWideCamera: \(Device.current.hasUltraWideCamera ? "Yes" : "No")
                    IsJailBroken: \(UIDevice.pt.isJailBroken ? "Yes" : "No")
                    """
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.NoActionCallBack,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.RestoreFirstKey
        {
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.RestoreUserDefult,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.AppUpdateKey
        {
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.AppUpdate,false,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.DEBUGKey || dataName == LocalConsole.NORMALKey
        {
            let newBool:Bool = !App_UI_Debug_Bool
            UserDefaults.standard.set(newBool, forKey: LocalConsole.ConsoleDebug)
            
            popoverTitles.enumerated().forEach { (index,value) in
                if value == LocalConsole.DEBUGKey
                {
                    popoverTitles[index] = LocalConsole.NORMALKey
                }
                else if value == LocalConsole.NORMALKey
                {
                    popoverTitles[index] = LocalConsole.DEBUGKey
                }
            }
            
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.Debug,newBool,URL(string: "nil")!)
            }
        }
        else if dataName == LocalConsole.DEBUGSETTINGKey
        {
            if consoleActionBlock != nil
            {
                consoleActionBlock!(.DebugSetting,false,URL(string: "nil")!)
            }
        }
    }

    public func print(_ items: Any) {
        if currentText == "" {
            currentText = "\(items)"
        } else {
            currentText = currentText + "\n\(items)"
        }
    }
}

public extension TimeInterval {
    var formattedString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: self)
    }
}

public class PTTerminal:PFloatingButton
{
    public var systemText : PTInvertedTextView?
    public lazy var menuButton = UIButton()
    public var systemIsVisible : Bool? = false

    override init(view:Any,frame:CGRect)
    {
        super.init(view: view, frame: frame)
        self.backgroundColor = .black
        self.draggable = true
        self.layer.shadowRadius = 16
        self.layer.shadowOpacity = 0.5
        self.shadowOffset = CGSize.init(width: 0, height: 2)
        self.layer.cornerRadius = 22
        self.tag = SystemLogViewTag
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }
        
        let borderView = UIView()
        borderView.layer.borderWidth = borderLine
        borderView.layer.borderColor = UIColor.randomColor.cgColor
        borderView.layer.cornerRadius = (self.layer.cornerRadius) + 1
        if #available(iOS 13.0, *) {
            borderView.layer.cornerCurve = .continuous
        }
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(borderView)
        borderView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        systemText = PTInvertedTextView()
        systemText?.isEditable = false
        systemText?.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        systemText?.isSelectable = false
        systemText?.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            systemText?.contentInsetAdjustmentBehavior = .never
        }
        systemText?.backgroundColor = .clear
        self.addSubview(systemText!)
        systemText?.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(borderLine * 4)
        }
        systemText?.layer.cornerRadius = (self.layer.cornerRadius) - 2
        if #available(iOS 13.0, *) {
            systemText?.layer.cornerCurve = .continuous
        }

        menuButton = UIButton.init(type: .custom)
        menuButton.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        if #available(iOS 13.0, *) {
            menuButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17)), for: .normal)
        } else {
            menuButton.setImage(UIImage.init(named: "icon_category"), for: .normal)
        }
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        self.addSubview(menuButton)
        menuButton.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(40)
            make.right.bottom.equalToSuperview().inset(borderLine)
        }
        menuButton.viewCorner(radius: diameter / 2)
        
        menuButton.tintColor = UIColor(white: 1, alpha: 0.75)
        systemIsVisible = true

    }
        
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        systemText?.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(borderLine * 4)
        }

        menuButton.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(40)
            make.right.bottom.equalToSuperview().inset(borderLine)
        }

    }
    
    public var fontSize: CGFloat? = LocalConsoleFontBaseSize {
        didSet {
            guard fontSize! >= LocalConsoleFontMin else { fontSize = LocalConsoleFontMin; return }
            guard fontSize! <= LocalConsoleFontMax else { fontSize = LocalConsoleFontMax; return }
            setAttributedText(systemText!.text)
        }
    }

    public func setAttributedText(_ string: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 7
        
        var attributes: [NSAttributedString.Key: Any]
        if #available(iOS 13.0, *) {
            attributes = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: fontSize!, weight: .semibold, design: .monospaced)
            ]
        } else {
            // Fallback on earlier versions
            attributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize!)]
        }
        
        systemText?.attributedText = NSAttributedString(string: string, attributes: attributes)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
