//
//  PTEditInputViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

class PTEditInputViewController: PTBaseViewController {
    private static let toolViewHeight: CGFloat = 70
    
    // 用于节流的高频绘制任务
    private var drawBgTask: Task<Void, Never>?
    
    private let image: UIImage?
    
    private var text: String
    
    private var font: UIFont = .boldSystemFont(ofSize: PTTextStickerView.fontSize)
    
    private var currentColor: UIColor {
        didSet {
            refreshTextViewUI()
        }
    }
    
    private var textStyle: PTInputTextStyle
    
    private lazy var cancelBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(PTImageEditorConfig.share.textBackImage, for: .normal)
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        btn.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return btn
    }()
    
    private lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(PTImageEditorConfig.share.textSubmitImage, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return btn
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .done
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.tintColor = .white
        textView.textColor = currentColor
        textView.text = text
        textView.font = font
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.delegate = self
        return textView
    }()
    
    private lazy var formatScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    private lazy var formatStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 15
        stack.alignment = .center
        return stack
    }()

    private lazy var toolView = UIView(frame: CGRect(x: 0, y: view.pt.jx_height - Self.toolViewHeight, width: view.pt.jx_width, height: Self.toolViewHeight))
    
    private lazy var textStyleBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addActionHandlers { _ in
            self.textStyleBtnClick()
        }
        return btn
    }()
    
    private lazy var drawColorButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.paintpalette), for: .normal)
        view.addActionHandlers { sender in
            let colorPicker = PTColorPickerContainerViewController()
            colorPicker.backButton.setImage(PTImageEditorConfig.share.colorPickerBackImage, for: .normal)
            colorPicker.picker.selectedColor = self.currentColor
            colorPicker.selectedColorCallback = { color in
                self.currentColor = color
            }
            self.navigationController?.pushViewController(colorPicker, completion: {
            })
        }
        return view
    }()
        
    private lazy var textLayer = CAShapeLayer()
    
    private let textLayerRadius: CGFloat = 10
    
    private let maxTextCount = 100
    
    /// text, textColor, image, style
    var endInput: ((String, UIColor, UIFont, UIImage?, PTInputTextStyle) -> Void)?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        true
    }
            
    public override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(cancelBtn)
        setCustomRightButtons(buttons: [doneBtn])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        changeStatusBar(type: .Auto)
    }

    init(image: UIImage?, text: String? = nil, textColor: UIColor? = nil, font: UIFont? = nil, style: PTInputTextStyle = PTInputTextStyle()) {
        self.image = image
        self.text = text ?? ""
        if let font = font {
            self.font = font.withSize(PTTextStickerView.fontSize)
        }
        if let textColor = textColor {
            currentColor = textColor
        } else {
            currentColor = PTImageEditorConfig.share.textStickerDefaultTextColor
        }
        textStyle = style
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        PTGCDManager.shared.delayOnMain(time: 0.35) {
            self.textView.becomeFirstResponder()
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        let bgImageView = UIImageView(image: image?.pt.blurImage(level: 4))
        bgImageView.frame = view.bounds
        bgImageView.contentMode = .scaleAspectFit
        view.addSubview(bgImageView)
        
        let coverView = UIView(frame: bgImageView.bounds)
        coverView.backgroundColor = .black
        coverView.alpha = 0.4
        bgImageView.addSubview(coverView)
        
        view.addSubviews([textView,toolView,formatScrollView])
        
        textView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(200)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
        }
        
        toolView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.height.equalTo(54)
        }
        toolView.addSubviews([textStyleBtn,drawColorButton])
        
        textStyleBtn.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.toolView.snp.centerX).offset(-15)
        }
        
        drawColorButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(self.textStyleBtn)
            make.left.equalTo(self.toolView.snp.centerX).offset(15)
        }
        
        formatScrollView.addSubview(formatStackView)
        
        // 布局格式栏 (紧贴在 toolView 上方)
        formatScrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(15)
            make.bottom.equalTo(toolView.snp.top)
            make.height.equalTo(44)
        }
        formatStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        setupFormatButtons()
        // 这个要放到这里，不能放到懒加载里，因为放到懒加载里会触发layoutManager(_:, didCompleteLayoutFor:,atEnd)，导致循环调用
        textView.textAlignment = .left
        
        refreshTextViewUI()
    }
    
    private func setupFormatButtons() {
        // 配置数据源: (SF Symbol 图标, 初始状态, 点击闭包)
        let buttonConfigs: [(String, Bool, (UIButton) -> Void)] = [
            ("bold", textStyle.isBold, { [weak self] btn in
                self?.textStyle.isBold.toggle()
                btn.tintColor = self?.textStyle.isBold == true ? .white : .gray
                self?.updateTextAttributes()
            }),
            ("italic", textStyle.isItalic, { [weak self] btn in
                self?.textStyle.isItalic.toggle()
                btn.tintColor = self?.textStyle.isItalic == true ? .white : .gray
                self?.updateTextAttributes()
            }),
            ("underline", textStyle.hasUnderline, { [weak self] btn in
                self?.textStyle.hasUnderline.toggle()
                btn.tintColor = self?.textStyle.hasUnderline == true ? .white : .gray
                self?.updateTextAttributes()
            }),
            ("strikethrough", textStyle.hasStrikethrough, { [weak self] btn in
                self?.textStyle.hasStrikethrough.toggle()
                btn.tintColor = self?.textStyle.hasStrikethrough == true ? .white : .gray
                self?.updateTextAttributes()
            }),
            ("textformat", false, { [weak self] _ in
                self?.showFontPicker()
            }),
            // 对齐方式按钮，默认左对齐，点击轮换
            ("text.alignleft", true, { [weak self] btn in
                guard let self = self else { return }
                if self.textStyle.alignment == .left {
                    self.textStyle.alignment = .center
                    btn.setImage(UIImage(.text.aligncenter), for: .normal)
                } else if self.textStyle.alignment == .center {
                    self.textStyle.alignment = .right
                    btn.setImage(UIImage(.text.alignright), for: .normal)
                } else {
                    self.textStyle.alignment = .left
                    btn.setImage(UIImage(.text.alignleft), for: .normal)
                }
                self.updateTextAttributes()
            })
        ]
        
        for config in buttonConfigs {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: config.0), for: .normal)
            btn.tintColor = config.1 ? .white : .gray // 选中白色，未选中灰色
            btn.addActionHandlers { _ in
                config.2(btn)
            }
            btn.snp.makeConstraints { make in
                make.size.equalTo(34)
            }
            formatStackView.addArrangedSubview(btn)
        }
    }
    
    // MARK: - 字体选择器 (UIFontPickerViewController)
    private func showFontPicker() {
        let config = UIFontPickerViewController.Configuration()
        config.includeFaces = true // 允许选择字体的具体字重 (如 Light, Black 等)
        config.displayUsingSystemFont = false // 强制使用字体原本的样貌展示列表
        
        let fontPicker = UIFontPickerViewController(configuration: config)
        fontPicker.delegate = self
        
        // 弹出选择器
        self.present(fontPicker, animated: true)
    }

    private func refreshTextViewUI() {
        textStyleBtn.setImage(textStyle.btnImage, for: .normal)
        textStyleBtn.setImage(textStyle.btnImage, for: .highlighted)
        // 统一走富文本更新逻辑
        updateTextAttributes()
    }
    
    @objc private func textStyleBtnClick() {
        if textStyle.bgStyle == .normal {
            textStyle.bgStyle = .bg
        } else {
            textStyle.bgStyle = .normal
        }

        refreshTextViewUI()
    }
    
    @objc private func cancelBtnClick() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func doneBtnClick() {
        
        textView.tintColor = .clear
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.endEditing(true)

        var image: UIImage?
        
        if let text = textView.text, !text.isEmpty {
            // 2. 获取所有的文字精准坐标块
            let rawRects = self.getRawTextRects()
            
            if !rawRects.isEmpty {
                // 3. 计算所有文字块的并集，得出最终的精准包围盒 (Bounding Box)
                var contentRect = rawRects[0]
                for r in rawRects {
                    contentRect = contentRect.union(r)
                }
                
                // 4. 开启画板，尺寸完美贴合文字
                image = UIGraphicsImageRenderer.pt.renderImage(size: contentRect.size) { context in
                    // 🌟 核心魔法：将上下文原点反向平移！
                    // 把包围盒的左上角平移到 (0,0) 位置，这样右对齐/居中的文字就会被完美拽回画面中心，绝不会被裁剪！
                    context.translateBy(x: -contentRect.minX, y: -contentRect.minY)
                    
                    // 将包含文字和彩色背景块的整个 Layer 渲染进去
                    self.textView.layer.render(in: context)
                }
            }
        }
        
        // 5. 回调并退出
        endInput?(textView.text, currentColor, font, image, textStyle)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = rect?.height ?? 366
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(x: 0, y: view.pt.jx_height - keyboardH - Self.toolViewHeight, width: view.pt.jx_width, height: Self.toolViewHeight)
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
    
    @objc private func keyboardWillHide(_ notify: Notification) {
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        let toolViewFrame = CGRect(
            x: 0,
            y: view.pt.jx_height - deviceSafeAreaInsets().bottom - Self.toolViewHeight,
            width: view.pt.jx_width,
            height: Self.toolViewHeight
        )
        
        var textViewFrame = textView.frame
        textViewFrame.size.height = toolViewFrame.minY - textViewFrame.minY - 20
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.toolView.frame = toolViewFrame
            self.textView.frame = textViewFrame
        }
    }
    
    // MARK: - 富文本属性更新
    private func updateTextAttributes() {
        // 处理字体：合成粗体与斜体
        let baseDescriptor = self.font.fontDescriptor
        var symTraits = baseDescriptor.symbolicTraits
        
        if textStyle.isBold {
            symTraits.insert(.traitBold)
        } else {
            symTraits.remove(.traitBold)
        }

        if textStyle.isItalic {
            symTraits.insert(.traitItalic)
        } else {
            symTraits.remove(.traitItalic)
        }
        
        // 尝试生成带有新特征的字体（有些特殊艺术字体可能不支持加粗/倾斜，需要安全降级）
        if let newDescriptor = baseDescriptor.withSymbolicTraits(symTraits) {
            self.font = UIFont(descriptor: newDescriptor, size: PTTextStickerView.fontSize)
        }
        
        textView.textAlignment = textStyle.alignment
        
        // 处理段落格式：对齐方式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textStyle.alignment
        
        // 确定最终文本颜色 (适配你之前的背景样式逻辑)
        var finalTextColor = currentColor
        if textStyle.bgStyle == .bg {
            finalTextColor = (currentColor == .white) ? .black : .white
        }
        
        // 组装富文本属性字典
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: finalTextColor,
            .paragraphStyle: paragraphStyle,
            .obliqueness: textStyle.isItalic ? 0.25 : 0
        ]
        
        if textStyle.hasUnderline {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if textStyle.hasStrikethrough {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        
        // 安全地应用到 TextView (保留用户的光标位置)
        let selectedRange = textView.selectedRange
        
        textView.typingAttributes = attributes
        if let currentText = textView.text, !currentText.isEmpty {
            textView.textStorage.beginEditing()
            let fullRange = NSRange(location: 0, length: textView.textStorage.length)
            textView.textStorage.setAttributes(attributes, range: fullRange)
            textView.textStorage.endEditing()
        }
        
        textView.selectedRange = selectedRange
        
        // 触发你之前的背景色块重绘
        drawTextBackground()
    }
}

// MARK: Draw text layer
extension PTEditInputViewController {
    
    @MainActor
    private func drawTextBackground() {
        guard textStyle.bgStyle == .bg, !textView.text.isEmpty else {
            textLayer.removeFromSuperlayer()
            return
        }
        
        // 取消上一次的任务（防手抖节流）
        drawBgTask?.cancel()
        
        // 开启 Swift 6 原生主线程 Task 进行节流
        drawBgTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            // 节流：等待 30 毫秒（iOS 16+ 现代 API）。
            // 如果用户这 30ms 内又打字了，Task 会被 cancel，抛出 CancellationError 并退出
            do {
                try await Task.sleep(for: .milliseconds(30))
            } catch {
                return // 任务被取消，直接退出
            }
            
            // 再次校验任务状态
            guard !Task.isCancelled else { return }
            // 获取原生排版矩形 (全部在安全的 MainActor 下执行)
            let rawRects = self.getRawTextRects()
            guard !rawRects.isEmpty else { return }
            
            let currentRadius = self.textLayerRadius
            let fillColor = self.currentColor.cgColor
            
            // 数学计算（数据量极小，主线程运算耗时极短，彻底避免并发隔离崩溃）
            let optimizedRects = Self.optimizeRects(rawRects, radius: currentRadius)
            let cgPath = Self.buildPath(from: optimizedRects, radius: currentRadius)
            
            // 光速渲染，关闭隐式动画省去开销
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            self.textLayer.path = cgPath
            self.textLayer.fillColor = fillColor
            if self.textLayer.superlayer == nil {
                self.textView.layer.insertSublayer(self.textLayer, at: 0)
            }
            
            CATransaction.commit()
        }
    }
    
    @MainActor
    private func getRawTextRects() -> [CGRect] {
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        
        // iOS 17 中安全的字形范围获取
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        guard glyphRange.length > 0 else { return [] }
        
        var rects: [CGRect] = []
        let insetLeft = textView.textContainerInset.left
        let insetTop = textView.textContainerInset.top
        
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, _, _ in
            // 过滤无用的幽灵矩形
            guard usedRect.width > 0 && usedRect.height > 0 else { return }
            
            rects.append(CGRect(x: usedRect.minX - 10 + insetLeft,
                                y: usedRect.minY - 8 + insetTop,
                                width: usedRect.width + 20,
                                height: usedRect.height + 16))
        }
        return rects
    }
    
    // 纯静态方法，断开与控制器的关联，满足 Swift 6 Sendable 严格要求
    private static func buildPath(from rects: [CGRect], radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        for (index, rect) in rects.enumerated() {
            if index == 0 {
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
                path.addArc(withCenter: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius, startAngle: .pi, endAngle: .pi * 1.5, clockwise: true)
                path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
                path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
            } else {
                let preRect = rects[index - 1]
                if rect.maxX > preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: rect.minY - radius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX + radius, y: rect.minY - radius), radius: radius, startAngle: -.pi, endAngle: -.pi * 1.5, clockwise: false)
                    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius, startAngle: .pi * 1.5, endAngle: .pi * 2, clockwise: true)
                } else if rect.maxX < preRect.maxX {
                    path.addLine(to: CGPoint(x: preRect.maxX, y: preRect.maxY - radius))
                    path.addArc(withCenter: CGPoint(x: preRect.maxX - radius, y: preRect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                    path.addLine(to: CGPoint(x: rect.maxX + radius, y: preRect.maxY))
                    path.addArc(withCenter: CGPoint(x: rect.maxX + radius, y: preRect.maxY + radius), radius: radius, startAngle: -.pi / 2, endAngle: -.pi, clockwise: false)
                } else {
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + radius))
                }
            }
            
            if index == rects.count - 1 {
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
                path.addArc(withCenter: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
                path.addArc(withCenter: CGPoint(x: rect.minX + radius, y: rect.maxY - radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                
                let firstRect = rects[0]
                path.addLine(to: CGPoint(x: firstRect.minX, y: firstRect.minY + radius))
                path.close()
            }
        }
        return path.cgPath
    }

    // 纯静态方法，断开与控制器的关联
    private static func optimizeRects(_ rects: [CGRect], radius: CGFloat) -> [CGRect] {
        guard rects.count > 1 else { return rects }
        var result = rects
        let threshold = radius * 2
        
        for i in 1..<result.count {
            let pre = result[i - 1]
            let curr = result[i]
            if curr.width > pre.width && (curr.width - pre.width) < threshold {
                result[i - 1].size.width = curr.width
            } else if curr.width < pre.width && (pre.width - curr.width) < threshold {
                result[i].size.width = pre.width
            }
        }
        
        for i in (1..<result.count).reversed() {
            let pre = result[i - 1]
            let curr = result[i]
            if curr.width > pre.width && (curr.width - pre.width) < threshold {
                result[i - 1].size.width = curr.width
            } else if curr.width < pre.width && (pre.width - curr.width) < threshold {
                result[i].size.width = pre.width
            }
        }
        
        return result
    }
}

extension PTEditInputViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let markedTextRange = textView.markedTextRange
        guard markedTextRange == nil || (markedTextRange?.isEmpty ?? true) else {
            return
        }
        
        let text = textView.text ?? ""
        if text.count > maxTextCount {
            let endIndex = text.index(text.startIndex, offsetBy: maxTextCount)
            textView.text = String(text[..<endIndex])
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == String.newline {
            doneBtnClick()
            return false
        }
        return true
    }
}

extension PTEditInputViewController: @MainActor NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        guard layoutFinishedFlag else {
            return
        }
        
        drawTextBackground()
    }
}

extension PTEditInputViewController: UIFontPickerViewControllerDelegate {
    
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        
        // 1. 获取用户选择的新字体 (保持我们规定的统一字号)
        let newFont = UIFont(descriptor: descriptor, size: PTTextStickerView.fontSize)
        
        // 2. 更新状态变量
        self.font = newFont
        
        // 3. 重新应用所有的粗体、斜体、对齐方式到新字体上
        updateTextAttributes()
        
        // 4. 用户选完字体后，界面会 dismiss，我们让输入框重新获取焦点，弹回键盘
        PTGCDManager.shared.delayOnMain(time: 0.3) {
            self.textView.becomeFirstResponder()
        }
    }
    
    func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
        // 用户取消选择，直接让键盘弹回来即可
        PTGCDManager.shared.delayOnMain(time: 0.3) {
            self.textView.becomeFirstResponder()
        }
    }
}
