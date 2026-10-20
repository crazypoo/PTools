//
//  PTCodeView.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/28.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif

public enum PTCodeRefreshReason: Equatable, Sendable {
    case tap
    case timer
    case programmatic
}

@MainActor
@objcMembers
public class PTCodeView: UIView {

    private struct CharacterRenderDescriptor {
        let value: String
        let xFactor: CGFloat
        let yFactor: CGFloat
        let angle: CGFloat
        let color: UIColor
    }

    private struct LineRenderDescriptor {
        let startX: CGFloat
        let startY: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        let color: UIColor
    }

    private enum DisplaySource {
        case generated
        case externalText(String)
        case externalImage(UIImage)
    }

    private let alphabetArr = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)
    private var numberOfCode = 0
    private var numberOfLine = 0
    private var changeTime: TimeInterval = 0
    private var dataSource = [String]()
    private var changeString = ""
    private var displaySource: DisplaySource = .generated
    private var refreshTask: Task<Void, Never>?
    private var isInBackground = false
    private var isAttachedToWindow = false
    private var lastTapDate: Date?
    private let tapThrottleInterval: TimeInterval = 0.5
    private var characterRenderDescriptors = [CharacterRenderDescriptor]()
    private var lineRenderDescriptors = [LineRenderDescriptor]()

    private let imageView = UIImageView()

    open var codeBlock: ((_ codeView: PTCodeView, _ code: String) -> Void)?

    // English: External content is refreshed by the host instead of being generated locally.
    // Español: El contenido externo se actualiza desde el host en lugar de generarse localmente.
    // 中文：外部内容由宿主负责刷新，控件本身不再生成外部内容。
    @nonobjc public var onRefreshRequested: ((PTCodeView, PTCodeRefreshReason) -> Void)?

    public var allowsTapToRefresh = true

    public var captchaImageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet {
            imageView.contentMode = captchaImageContentMode
        }
    }

    public init(numberOfCodes: Int = 4,
                numberOfLines: Int = 4,
                changeTimes: TimeInterval) {
        numberOfCode = max(0, numberOfCodes)
        numberOfLine = max(0, numberOfLines)
        changeTime = Self.sanitizedInterval(changeTimes)
        super.init(frame: .zero)

        for index in 0..<10 {
            dataSource.append(String(index))
        }
        dataSource.append(contentsOf: alphabetArr)
        dataSource.append(contentsOf: alphabetArr.map { $0.lowercased() })

        configureView()
        backgroundColor = UIColor.randomColor
        generateLocalCode(notify: false)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        isAttachedToWindow = window != nil
        if isAttachedToWindow {
            restartRefreshTaskIfNeeded()
        } else {
            stopRefreshTask()
        }
    }

    public override func removeFromSuperview() {
        stopRefreshTask()
        isAttachedToWindow = false
        super.removeFromSuperview()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds.integral
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard rect.width > 0, rect.height > 0 else { return }
        guard case .externalImage = displaySource else {
            drawTextAndLines(in: rect)
            return
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleRefresh(reason: .tap)
    }

    // English: Store externally supplied text without invoking a refresh callback.
    // Español: Guarda el texto externo sin invocar el callback de actualización.
    // 中文：设置外部文本时只更新显示，不触发刷新回调。
    public func setCode(_ code: String) {
        displaySource = .externalText(code)
        applyTextDisplay()
    }

    // English: Reuse one image view so image mode never overlaps text rendering.
    // Español: Reutiliza una sola vista de imagen para que el modo imagen no se mezcle con el texto.
    // 中文：复用同一个图片视图，避免图片模式与文本绘制叠加。
    public func setCodeImage(_ image: UIImage) {
        displaySource = .externalImage(image)
        changeString = ""
        characterRenderDescriptors.removeAll(keepingCapacity: true)
        lineRenderDescriptors.removeAll(keepingCapacity: true)
        imageView.image = image
        imageView.contentMode = captchaImageContentMode
        imageView.isHidden = false
        updateAccessibilityValue()
        setNeedsDisplay()
    }

    public func useLocalGeneratedCode() {
        displaySource = .generated
        generateLocalCode(notify: true)
    }

    // English: Zero disables automatic refresh and cancels the previous scheduler.
    // Español: Cero desactiva la actualización automática y cancela el planificador anterior.
    // 中文：传入 0 会关闭自动刷新并取消之前的调度任务。
    public func setRefreshInterval(_ seconds: TimeInterval) {
        changeTime = Self.sanitizedInterval(seconds)
        restartRefreshTaskIfNeeded()
    }

    public func requestRefresh() {
        handleRefresh(reason: .programmatic)
    }

    public func clearCodeContent() {
        displaySource = .externalText("")
        changeString = ""
        applyTextDisplay()
    }

    public func changeCode() {
        requestRefresh()
    }

    private func configureView() {
        isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityLabel = "验证码"
        accessibilityTraits = [.button]
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "刷新验证码", target: self, selector: #selector(accessibilityRefresh))
        ]

        imageView.isHidden = true
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.isAccessibilityElement = false
        addSubview(imageView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private static func sanitizedInterval(_ value: TimeInterval) -> TimeInterval {
        guard value.isFinite, value > 0 else { return 0 }
        // English: shortcut: cap automatic refresh at 24 hours to keep nanosecond conversion safe; use a host scheduler for longer periods.
        // Español: atajo: limita la actualización automática a 24 horas para mantener segura la conversión a nanosegundos; usa un planificador del host para periodos mayores.
        // 中文：捷径：将自动刷新限制为 24 小时以保证纳秒转换安全；更长周期请使用宿主调度器。
        return min(value, 86_400)
    }

    private func handleRefresh(reason: PTCodeRefreshReason) {
        if case .tap = reason {
            guard allowsTapToRefresh else { return }
            let now = Date()
            if let lastTapDate, now.timeIntervalSince(lastTapDate) < tapThrottleInterval {
                return
            }
            lastTapDate = now
        }

        switch displaySource {
        case .generated:
            generateLocalCode(notify: true)
        case .externalText, .externalImage:
            onRefreshRequested?(self, reason)
        }
    }

    private func generateLocalCode(notify: Bool) {
        displaySource = .generated
        let generated = (0..<numberOfCode).compactMap { _ in dataSource.randomElement() }.joined()
        changeString = generated
        rebuildRenderDescriptors()
        imageView.image = nil
        imageView.isHidden = true
        updateAccessibilityValue()
        setNeedsDisplay()
        if notify {
            codeBlock?(self, generated)
        }
    }

    private func applyTextDisplay() {
        imageView.image = nil
        imageView.isHidden = true
        rebuildRenderDescriptors()
        updateAccessibilityValue()
        setNeedsDisplay()
    }

    private func updateAccessibilityValue() {
        switch displaySource {
        case .externalImage:
            accessibilityValue = "图片验证码"
        case .generated, .externalText:
            accessibilityValue = currentText.isEmpty ? "空验证码" : "可刷新验证码"
        }
    }

    private var currentText: String {
        switch displaySource {
        case .generated:
            return changeString
        case .externalText(let text):
            return text
        case .externalImage:
            return ""
        }
    }

    private func rebuildRenderDescriptors() {
        let text = currentText
        guard !text.isEmpty else {
            characterRenderDescriptors.removeAll(keepingCapacity: true)
            lineRenderDescriptors.removeAll(keepingCapacity: true)
            return
        }

        characterRenderDescriptors = Array(text).map {
            CharacterRenderDescriptor(
                value: String($0),
                xFactor: CGFloat.random(in: 0...1),
                yFactor: CGFloat.random(in: 0...1),
                angle: CGFloat.random(in: -0.15...0.15),
                color: UIColor.randomColor
            )
        }
        lineRenderDescriptors = (0..<numberOfLine).map { _ in
            LineRenderDescriptor(
                startX: CGFloat.random(in: 0...1),
                startY: CGFloat.random(in: 0...1),
                endX: CGFloat.random(in: 0...1),
                endY: CGFloat.random(in: 0...1),
                color: UIColor.randomColor
            )
        }
    }

    private func drawTextAndLines(in rect: CGRect) {
        let text = currentText
        guard !text.isEmpty else { return }

        let fontSize = max(1, min(20, rect.height * 0.5))
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let columnWidth = rect.width / CGFloat(max(characterRenderDescriptors.count, 1))

        for (index, descriptor) in characterRenderDescriptors.enumerated() {
            let characterSize = (descriptor.value as NSString).size(withAttributes: attributes)
            let availableX = max(0, columnWidth - characterSize.width)
            let maxX = max(0, rect.width - characterSize.width)
            let maxY = max(0, rect.height - characterSize.height)
            let x = min(
                maxX,
                max(0, columnWidth * CGFloat(index) + availableX * descriptor.xFactor)
            )
            let y = min(
                maxY,
                max(0, maxY * descriptor.yFactor)
            )

            guard let context = UIGraphicsGetCurrentContext() else { continue }
            context.saveGState()
            context.translateBy(x: x + characterSize.width / 2, y: y + characterSize.height / 2)
            context.rotate(by: descriptor.angle)
            (descriptor.value as NSString).draw(
                at: CGPoint(x: -characterSize.width / 2, y: -characterSize.height / 2),
                withAttributes: [
                    .font: font,
                    .foregroundColor: descriptor.color
                ]
            )
            context.restoreGState()
        }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(1)
        for descriptor in lineRenderDescriptors {
            context.setStrokeColor(descriptor.color.cgColor)
            context.move(to: CGPoint(x: rect.width * descriptor.startX, y: rect.height * descriptor.startY))
            context.addLine(to: CGPoint(x: rect.width * descriptor.endX, y: rect.height * descriptor.endY))
            context.strokePath()
        }
    }

    private func restartRefreshTaskIfNeeded() {
        stopRefreshTask()
        guard isAttachedToWindow, !isInBackground, changeTime > 0 else { return }

        let nanoseconds = UInt64(max(0.01, changeTime) * 1_000_000_000)
        refreshTask = Task { @MainActor [weak self] in
            do {
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: nanoseconds)
                    guard let self, !Task.isCancelled, self.isAttachedToWindow, !self.isInBackground else {
                        return
                    }
                    self.handleRefresh(reason: .timer)
                }
            } catch is CancellationError {
                // English: Cancellation is the normal lifecycle path, not a refresh failure.
                // Español: La cancelación es el flujo normal del ciclo de vida, no un fallo de actualización.
                // 中文：取消是正常生命周期路径，不应被视为刷新失败。
            } catch {
                // English: A cancelled task is the only expected scheduler termination.
                // Español: La terminación esperada del planificador es una tarea cancelada。
                // 中文：调度任务预期只会因取消而结束。
            }
        }
    }

    private func stopRefreshTask() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    @objc private func handleDidEnterBackground() {
        isInBackground = true
        stopRefreshTask()
    }

    @objc private func handleWillEnterForeground() {
        isInBackground = false
        restartRefreshTaskIfNeeded()
    }

    @objc private func accessibilityRefresh(_ action: UIAccessibilityCustomAction) -> Bool {
        handleRefresh(reason: .tap)
        return true
    }
}
