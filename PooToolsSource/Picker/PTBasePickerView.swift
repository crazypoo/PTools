//
//  PTBasePickerView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/6/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import Foundation
#if SWIFT_PACKAGE
import ptools
#endif

public protocol PTPickerStringModel: Sendable {
    /// 告訴選擇器，滾輪上應該顯示什麼文字
    var pickerDisplayText: String { get }
}

/// 讓原生的 String 直接遵守協議，保證向後兼容！
extension String: PTPickerStringModel {
    public var pickerDisplayText: String { return self }
}

// MARK: - 樹狀數據協議
/// 支援多級聯動的 Model，必須遵守此協議
public protocol PTTreePickerModel: PTPickerStringModel {
    /// 該節點下的子節點集合（如果沒有子節點，返回空數組 [] 即可）
    var pickerChildren: [PTTreePickerModel] { get }
}

public struct PTPickerResult: Sendable {
    /// 該項在當前列中的索引
    public let index: Int
    /// 顯示的文字內容
    public let value: String
    
    public let originalModel: PTPickerStringModel
}

fileprivate enum PTDateComponent: Sendable {
    case year, month, day, hour, minute, second, quarter, weekOfYear, weekOfMonth
}

public enum PTDatePickerMode: Sendable {
    // --- 常用系統級樣式 (我們用自定義引擎渲染以統一樣式) ---
    /// 【yyyy-MM-dd】年月日
    case ymd
    /// 【yyyy-MM-dd HH:mm】年月日時分
    case ymdhm
    /// 【HH:mm】時分
    case hm
    
    // --- 自定義樣式 ---
    /// 【yyyy-MM-dd HH:mm:ss】年月日時分秒
    case ymdhms
    /// 【yyyy-MM-dd HH】年月日時
    case ymdh
    /// 【MM-dd HH:mm】月日時分
    case mdhm
    /// 【yyyy-MM】年月
    case ym
    /// 【yyyy】年
    case y
    /// 【MM-dd】月日
    case md
    /// 【HH:mm:ss】時分秒
    case hms
    /// 【mm:ss】分秒
    case ms
    /// 【yyyy-qq】年季度
    case yq
    /// 【yyyy-MM-ww】年月周
    case ymw
    /// 【yyyy-ww】年周
    case yw
}

/// EN: Describes an invalid date-picker configuration.
/// ES: Describe una configuración no válida del selector de fechas.
/// 中文：描述日期 Picker 的无效配置。
public enum PTDatePickerConfigurationError: Error, Sendable, Equatable {
    case reversedRange
    case noRepresentableDate
}

@MainActor
public struct PTPickerStyle: Sendable {
    
    // MARK: - Toolbar (顶部工具栏)
    /// 工具栏背景色
    public var toolbarBackgroundColor: UIColor = .secondarySystemBackground
    /// 容器(底部背景)颜色
    public var containerBackgroundColor: UIColor = .clear
    
    // MARK: - Cancel Button (取消按钮)
    public var cancelText: String = "取消"
    public var cancelTextColor: UIColor = .systemGray
    public var cancelTextFont: UIFont = .systemFont(ofSize: 16)
    
    // MARK: - Confirm Button (确定按钮)
    public var confirmText: String = "確認"
    public var confirmTextColor: UIColor = .systemBlue
    public var confirmTextFont: UIFont = .systemFont(ofSize: 16)
    
    // MARK: - Title Label (标题)
    public var titleTextColor: UIColor = .label
    public var titleTextFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
    
    // MARK: - Picker Title Label (标题)
    public var pickerTextColor: UIColor = .label
    public var pickerTextFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
    public var pickerRowHeight: CGFloat = 44.0
    
    public var pickerBackgroundColor: UIColor = .systemBackground
    
    public var toolBarTopBottomSpacing:CGFloat = 2.5
    
    public var containerCornerRaidus:CGFloat = 16
    public var pickerContainerCornerRaidus:CGFloat = 16
    // MARK: - Global Default Instance
    /// 全局默认配置，你可以在 AppDelegate 或初始化时修改它，从而统一整个 App 的选择器风格
    public static var shared = PTPickerStyle()
    
    public init() {}
}

@MainActor
open class PTBasePickerView: UIView {
    // MARK: - UI Components
    /// 半透明背景遮罩
    public let backgroundView = UIView()
    /// 底部白色容器，容纳工具栏和选择器
    public let containerView = UIView()
    /// 顶部工具栏容器
    public let toolbarView = UIView()

    public let pickerContainer = UIView()
    private let pickerMaskGlassView = UIVisualEffectView()

    public let titleLabel = UIButton(type: .custom)
    public let cancelButton = UIButton(type: .custom)
    public let confirmButton = UIButton(type: .custom)
    
    // MARK: - Properties
    private let containerHeight: CGFloat = 300.0
    private let toolbarHeight: CGFloat = 50.0
    private enum PresentationMode {
        case embedded
        case presented
        case dismissing
    }

    private var presentationMode: PresentationMode = .embedded
    private var presentationGeneration = 0
    private var isUIConfigured = false

    /// EN: Shows the toolbar when the picker is embedded in another view.
    /// ES: Muestra la barra cuando el selector está incrustado en otra vista.
    /// 中文：Picker 直接嵌入其他 View 时是否显示工具栏。
    public var showsToolbarWhenEmbedded = false {
        didSet {
            guard oldValue != showsToolbarWhenEmbedded else { return }
            updateToolbarVisibility()
            invalidateIntrinsicContentSize()
        }
    }

    /// EN: Reports whether the picker is currently presented as an overlay.
    /// ES: Indica si el selector está presentado actualmente como superposición.
    /// 中文：返回 Picker 当前是否以弹窗覆盖层方式展示。
    public private(set) var isPresented = false

    /// EN: Called when the user cancels the picker.
    /// ES: Se llama cuando el usuario cancela el selector.
    /// 中文：用户取消 Picker 时回调。
    public var onCancel: (@MainActor @Sendable () -> Void)?

    public var pickerStyle: PTPickerStyle = PTPickerStyle.shared {
        didSet {
            applyPickerStyle()
        }
    }
    
    public init(style: PTPickerStyle? = nil) {
        self.pickerStyle = style ?? PTPickerStyle.shared
        super.init(frame: .zero)
        setupUI()
    }

    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // EN: Build the hierarchy before activating constraints.
        // ES: Construye la jerarquía antes de activar las restricciones.
        // 中文：先完成视图层级，再激活约束，避免跨层级约束崩溃。
        backgroundView.alpha = 0
        backgroundView.isHidden = true
        backgroundView.isUserInteractionEnabled = false
        backgroundView.accessibilityElementsHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelAction))
        backgroundView.addGestureRecognizer(tapGesture)
        addSubviews([backgroundView, containerView])
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.viewCornerRectCorner(topLeft: pickerStyle.containerCornerRaidus,
                                           topRight: pickerStyle.containerCornerRaidus,
                                           corner: [.topLeft, .topRight])
        
        // 设置工具栏
        containerView.addSubviews([toolbarView, pickerContainer])
        toolbarView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0)
        }

        pickerContainer.snp.makeConstraints { make in
            make.top.equalTo(toolbarView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        pickerContainer.viewCornerRectCorner(topLeft: pickerStyle.pickerContainerCornerRaidus,
                                             topRight: pickerStyle.pickerContainerCornerRaidus,
                                             corner: [.topLeft, .topRight])

        var buttonClearGlassOffset:CGFloat = 5
        if #available(iOS 26.0, *) {
            pickerMaskGlassView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            pickerMaskGlassView.backgroundColor = pickerStyle.pickerBackgroundColor
            pickerContainer.addSubview(pickerMaskGlassView)
            pickerMaskGlassView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            cancelButton.configuration = UIButton.Configuration.clearGlass()
            confirmButton.configuration = UIButton.Configuration.clearGlass()
            titleLabel.configuration = UIButton.Configuration.clearGlass()
            buttonClearGlassOffset += 25
        } else {
            pickerContainer.backgroundColor = pickerStyle.pickerBackgroundColor
        }

        // 配置按钮和标题
        cancelButton.titleLabel?.font = pickerStyle.cancelTextFont
        cancelButton.titleLabel?.numberOfLines = 1
        cancelButton.setTitle(pickerStyle.cancelText, for: .normal)
        cancelButton.setTitleColor(pickerStyle.cancelTextColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        let cancelW = self.cancelButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        
        confirmButton.titleLabel?.font = pickerStyle.confirmTextFont
        confirmButton.titleLabel?.numberOfLines = 1
        confirmButton.setTitle(pickerStyle.confirmText, for: .normal)
        confirmButton.setTitleColor(pickerStyle.confirmTextColor, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        let confirmW = self.confirmButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        
        titleLabel.isUserInteractionEnabled = false
        titleLabel.isHidden = true
        titleLabel.titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel.setTitleColor(pickerStyle.titleTextColor, for: .normal)
        titleLabel.titleLabel?.font = pickerStyle.titleTextFont
        titleLabel.titleLabel?.textAlignment = .center
        toolbarView.addSubviews([cancelButton, confirmButton, titleLabel])
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.equalTo(cancelW)
            make.top.bottom.equalToSuperview().inset(self.pickerStyle.toolBarTopBottomSpacing)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.equalTo(confirmW)
            make.top.bottom.equalToSuperview().inset(self.pickerStyle.toolBarTopBottomSpacing)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(self.pickerStyle.toolBarTopBottomSpacing)
            make.leading.greaterThanOrEqualTo(cancelButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(confirmButton.snp.leading).offset(-8)
        }

        isUIConfigured = true
        applyPickerStyle()
        applyContainerLayout(for: .embedded)
    }
    
    public func resetTitleLabelwidth() {
        titleLabel.isHidden = (titleLabel.currentTitle ?? "").stringIsEmpty()
        setNeedsLayout()
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric,
               height: showsToolbarWhenEmbedded ? containerHeight : containerHeight - toolbarHeight)
    }

    private func applyPickerStyle() {
        guard isUIConfigured else { return }

        containerView.backgroundColor = pickerStyle.containerBackgroundColor
        if #available(iOS 26.0, *) {
            toolbarView.backgroundColor = .clear
            pickerMaskGlassView.backgroundColor = pickerStyle.pickerBackgroundColor
        } else {
            toolbarView.backgroundColor = pickerStyle.toolbarBackgroundColor
            pickerContainer.backgroundColor = pickerStyle.pickerBackgroundColor
        }

        cancelButton.titleLabel?.font = pickerStyle.cancelTextFont
        cancelButton.setTitle(pickerStyle.cancelText, for: .normal)
        cancelButton.setTitleColor(pickerStyle.cancelTextColor, for: .normal)
        confirmButton.titleLabel?.font = pickerStyle.confirmTextFont
        confirmButton.setTitle(pickerStyle.confirmText, for: .normal)
        confirmButton.setTitleColor(pickerStyle.confirmTextColor, for: .normal)
        titleLabel.setTitleColor(pickerStyle.titleTextColor, for: .normal)
        titleLabel.titleLabel?.font = pickerStyle.titleTextFont
        resetTitleLabelwidth()
    }

    private func updateToolbarVisibility() {
        guard isUIConfigured else { return }
        let shouldShow = presentationMode != .embedded || showsToolbarWhenEmbedded
        toolbarView.isHidden = !shouldShow
        toolbarView.snp.updateConstraints { make in
            make.height.equalTo(shouldShow ? toolbarHeight : 0)
        }
    }

    private func applyContainerLayout(for mode: PresentationMode) {
        guard isUIConfigured else { return }
        presentationMode = mode
        updateToolbarVisibility()

        switch mode {
        case .embedded:
            containerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        case .presented, .dismissing:
            containerView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(containerHeight)
                make.bottom.equalToSuperview().offset(mode == .dismissing ? containerHeight : 0)
            }
        }
    }

    private func animate(_ animated: Bool, animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        if !animated || UIAccessibility.isReduceMotionEnabled {
            UIView.performWithoutAnimation {
                animations()
                layoutIfNeeded()
            }
            completion?()
            return
        }

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: {
                           animations()
                           self.layoutIfNeeded()
                       },
                       completion: { _ in completion?() })
    }

    /// EN: Reuses one label style for every wheel picker.
    /// ES: Reutiliza un único estilo de etiqueta para todos los selectores.
    /// 中文：统一复用三个滚轮 Picker 的文本 Label 样式。
    fileprivate func pickerLabel(reusing view: UIView?, text: String?) -> UILabel {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.textColor = pickerStyle.pickerTextColor
        label.font = pickerStyle.pickerTextFont
        label.backgroundColor = .clear
        label.text = text
        return label
    }
    
    // MARK: - Actions
    /// EN: Subclasses override this when the current selection is invalid.
    /// ES: Las subclases lo redefinen cuando la selección actual no es válida.
    /// 中文：子类在当前选择无效时重写此属性。
    open var canConfirm: Bool { true }

    /// 子类需重写此方法以处理确定逻辑
    @objc open func confirmAction() {
        guard canConfirm else { return }
        dismiss()
    }
    
    // MARK: - Animations
    public func show() {
        guard let window = PTSceneContext.activeWindow() else { return }
        _ = show(in: window)
    }

    /// EN: Presents the picker over an explicit host view.
    /// ES: Presenta el selector sobre una vista anfitriona explícita.
    /// 中文：在指定的宿主 View 上以覆盖层方式展示 Picker。
    @discardableResult
    public func show(in hostView: UIView, animated: Bool = true) -> Bool {
        guard hostView !== self,
              (superview == nil || superview === hostView) else { return false }

        if superview == nil {
            hostView.addSubview(self)
        }
        snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        presentationGeneration += 1
        let generation = presentationGeneration
        isPresented = true
        backgroundView.isHidden = false
        backgroundView.isUserInteractionEnabled = true
        backgroundView.alpha = 0
        confirmButton.isEnabled = canConfirm
        accessibilityViewIsModal = true
        applyContainerLayout(for: .presented)
        // EN: Start below the host before animating into place.
        // ES: Comienza debajo del anfitrión antes de animarse a su posición.
        // 中文：动画开始前先将容器放到宿主视图底部之外。
        containerView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(containerHeight)
        }
        layoutIfNeeded()
        animate(animated, animations: {
            self.backgroundView.alpha = 1
            self.containerView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(0)
            }
        })
        if generation != presentationGeneration { return false }
        return true
    }

    @objc public func dismiss() {
        dismiss(animated: true)
    }

    /// EN: Dismisses only an overlay presentation; embedded pickers remain owned by their host.
    /// ES: Solo cierra una presentación superpuesta; los selectores incrustados siguen siendo del anfitrión.
    /// 中文：只关闭弹窗覆盖层；直接嵌入的 Picker 仍由宿主负责移除。
    public func dismiss(animated: Bool) {
        guard presentationMode == .presented, isPresented else { return }

        presentationGeneration += 1
        let generation = presentationGeneration
        presentationMode = .dismissing
        backgroundView.isUserInteractionEnabled = false
        animate(animated, animations: {
            self.backgroundView.alpha = 0
            self.containerView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().offset(self.containerHeight)
            }
        }) { [weak self] in
            guard let self,
                  self.presentationGeneration == generation,
                  self.presentationMode == .dismissing else { return }
            self.isPresented = false
            self.backgroundView.isHidden = true
            self.accessibilityViewIsModal = false
            self.presentationMode = .embedded
            self.removeFromSuperview()
            self.applyContainerLayout(for: .embedded)
        }
    }

    @objc private func cancelAction() {
        onCancel?()
        dismiss()
    }
}

@MainActor
public class PTStringPickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    private let pickerView = UIPickerView()
    private var dataSource: [[PTPickerStringModel]] = []
    private var selectedRows: [Int] = []

    /// EN: Emits a stable snapshot after a user or programmatic selection change.
    /// ES: Emite una instantánea estable después de cambiar la selección.
    /// 中文：用户或程序修改选择后，回调稳定的结果快照。
    public var onSelectionChanged: (@MainActor @Sendable ([PTPickerResult]) -> Void)?

    public var singleResultBlock: ((_ result: PTPickerResult) -> Void)?
    public var multiResultBlock: ((_ results: [PTPickerResult]) -> Void)?

    public override var canConfirm: Bool {
        !dataSource.isEmpty &&
        dataSource.allSatisfy { !$0.isEmpty } &&
        selectedRows.count == dataSource.count &&
        selectedRows.enumerated().allSatisfy { component, row in
            dataSource.indices.contains(component) && dataSource[component].indices.contains(row)
        }
    }

    public var selectedIndex: Int { selectedRows.first ?? -1 }

    public var selectedIndices: [Int] { selectedRows }

    public var currentResults: [PTPickerResult] {
        selectedRows.enumerated().compactMap { component, row in
            guard dataSource.indices.contains(component),
                  dataSource[component].indices.contains(row) else { return nil }
            let model = dataSource[component][row]
            return PTPickerResult(index: row, value: model.pickerDisplayText, originalModel: model)
        }
    }

    public override init(style: PTPickerStyle? = nil) {
        super.init(style: style)
        setupPicker()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPicker()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPicker()
    }

    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerContainer.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// EN: Configures data without presenting the picker.
    /// ES: Configura los datos sin presentar el selector.
    /// 中文：只配置数据，不展示 Picker。
    public func configure(title: String, data: [PTPickerStringModel], defaultIndex: Int = 0) {
        configure(title: title, multiData: [data], defaultIndices: [defaultIndex])
    }

    /// EN: Configures multiple columns without presenting the picker.
    /// ES: Configura varias columnas sin presentar el selector.
    /// 中文：只配置多列数据，不展示 Picker。
    public func configure(title: String, multiData: [[PTPickerStringModel]], defaultIndices: [Int]? = nil) {
        titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        dataSource = multiData
        selectedRows = multiData.indices.map { component in
            let preferredRow = defaultIndices.flatMap { $0.indices.contains(component) ? $0[component] : nil } ?? 0
            return normalizedRow(preferredRow, component: component)
        }
        singleResultBlock = nil
        multiResultBlock = nil
        reloadPickerAndRestoreSelection()
        updateConfirmButtonState()
    }

    public func show(title: String, data: [PTPickerStringModel], defaultIndex: Int = 0, completion: @escaping (PTPickerResult) -> Void) {
        configure(title: title, data: data, defaultIndex: defaultIndex)
        singleResultBlock = completion
        show()
    }

    public func show(title: String, multiData: [[PTPickerStringModel]], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) {
        configure(title: title, multiData: multiData, defaultIndices: defaultIndices)
        multiResultBlock = completion
        show()
    }

    /// EN: Selects a valid row and optionally emits the live-selection callback.
    /// ES: Selecciona una fila válida y puede emitir el callback de selección.
    /// 中文：选择有效行，并可选择是否触发实时选择回调。
    public func selectRow(_ row: Int, inComponent component: Int, animated: Bool = false, notifySelectionChanged: Bool = true) {
        guard dataSource.indices.contains(component) else { return }
        let safeRow = normalizedRow(row, component: component)
        guard safeRow >= 0 else { return }
        selectedRows[component] = safeRow
        pickerView.selectRow(safeRow, inComponent: component, animated: animated)
        updateConfirmButtonState()
        if notifySelectionChanged { onSelectionChanged?(currentResults) }
    }

    public override func confirmAction() {
        guard canConfirm else { return }
        let results = currentResults
        if let singleResultBlock, let firstResult = results.first {
            singleResultBlock(firstResult)
        } else if let multiResultBlock {
            multiResultBlock(results)
        }
        super.confirmAction()
    }

    private func normalizedRow(_ row: Int, component: Int) -> Int {
        guard dataSource.indices.contains(component), !dataSource[component].isEmpty else { return -1 }
        return min(max(row, 0), dataSource[component].count - 1)
    }

    private func reloadPickerAndRestoreSelection() {
        pickerView.reloadAllComponents()
        for component in dataSource.indices {
            let row = selectedRows[component]
            guard row >= 0 else { continue }
            pickerView.selectRow(row, inComponent: component, animated: false)
        }
    }

    private func updateConfirmButtonState() {
        confirmButton.isEnabled = canConfirm
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int { dataSource.count }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        dataSource.indices.contains(component) ? dataSource[component].count : 0
    }

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        pickerStyle.pickerRowHeight
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let text = dataSource.indices.contains(component) && dataSource[component].indices.contains(row)
            ? dataSource[component][row].pickerDisplayText
            : nil
        return pickerLabel(reusing: view, text: text)
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard dataSource.indices.contains(component) else { return }
        let safeRow = normalizedRow(row, component: component)
        guard safeRow >= 0 else { return }
        selectedRows[component] = safeRow
        updateConfirmButtonState()
        onSelectionChanged?(currentResults)
    }
}

@MainActor
public class PTDatePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    private let pickerView = UIPickerView()
    private var pickerMode: PTDatePickerMode = .ymd
    private var calendar = Calendar.current
    private var referenceDate = Date()
    private var dateIsConfigured = false
    
    // 【新增】邊界日期
    private var minDate: Date?
    private var maxDate: Date?
    
    // --- 動態數據源 ---
    private var yearArray: [Int] = []
    private var monthArray: [Int] = Array(1...12)
    private var dayArray: [Int] = []
    private var hourArray: [Int] = Array(0...23)
    private var minuteArray: [Int] = Array(0...59)
    private var secondArray: [Int] = Array(0...59)
    private var quarterArray: [Int] = Array(1...4)
    private var weekArray: [Int] = []
    
    // --- 當前選中的值 ---
    private var selectedYear: Int = 0
    private var selectedMonth: Int = 1
    private var selectedDay: Int = 1
    private var selectedHour: Int = 0
    private var selectedMinute: Int = 0
    private var selectedSecond: Int = 0
    private var selectedQuarter: Int = 1
    private var selectedWeek: Int = 1

    /// EN: Reports why the current date selection cannot be confirmed.
    /// ES: Indica por qué no se puede confirmar la selección de fecha actual.
    /// 中文：返回当前日期选择不能确认的原因。
    public private(set) var configurationError: PTDatePickerConfigurationError?

    /// EN: Emits the validated date snapshot after a user selection.
    /// ES: Emite una instantánea de fecha validada después de una selección.
    /// 中文：用户选择后回调经过校验的日期快照。
    public var onSelectionChanged: (@MainActor @Sendable (Date, String) -> Void)?

    public override var canConfirm: Bool {
        dateIsConfigured && configurationError == nil && currentSelectedDate != nil
    }
    
    // MARK: - Current Selection Properties
    /// 实时获取当前选中的日期对象
    public var currentSelectedDate: Date? {
        resolvedSelectedDate()
    }

    public var resultBlock: ((_ date: Date, _ dateString: String) -> Void)?
    
    // MARK: - Initialization
    public override init(style: PTPickerStyle? = nil) {
        super.init(style: style)
        setupPicker()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPicker()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPicker()
    }
    
    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerContainer.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Component Architecture
    private var componentLayout: [PTDateComponent] {
        switch pickerMode {
        case .ymd: return [.year, .month, .day]
        case .ymdhm: return [.year, .month, .day, .hour, .minute]
        case .hm: return [.hour, .minute]
        case .ymdhms: return [.year, .month, .day, .hour, .minute, .second]
        case .ymdh: return [.year, .month, .day, .hour]
        case .mdhm: return [.month, .day, .hour, .minute]
        case .ym: return [.year, .month]
        case .y: return [.year]
        case .md: return [.month, .day]
        case .hms: return [.hour, .minute, .second]
        case .ms: return [.minute, .second]
        case .yq: return [.year, .quarter]
        case .ymw: return [.year, .month, .weekOfMonth]
        case .yw: return [.year, .weekOfYear]
        }
    }
    
    // MARK: - Public Methods
    /// EN: Configures the date picker without presenting it.
    /// ES: Configura el selector de fechas sin presentarlo.
    /// 中文：只配置日期 Picker，不展示界面。
    public func configure(title: String,
                          mode: PTDatePickerMode = .ymd,
                          defaultDate: Date = Date(),
                          minDate: Date? = nil,
                          maxDate: Date? = nil) {
        titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        pickerMode = mode
        referenceDate = defaultDate
        calendar = Calendar.current
        self.minDate = minDate
        self.maxDate = maxDate
        resultBlock = nil
        if let minDate, let maxDate, minDate > maxDate {
            configurationError = .reversedRange
        } else {
            configurationError = nil
        }
        dateIsConfigured = true

        buildYearArray()
        updateSelectedValues(from: defaultDate)
        updateDynamicArrays()
        validateBoundary()
        pickerView.reloadAllComponents()
        scrollToDefaultPosition(animated: false)
        updateConfirmButtonState()
    }

    public func show(title: String,
                     mode: PTDatePickerMode = .ymd,
                     defaultDate: Date = Date(),
                     minDate: Date? = nil,
                     maxDate: Date? = nil,
                     completion: @escaping (Date, String) -> Void) {
        configure(title: title, mode: mode, defaultDate: defaultDate, minDate: minDate, maxDate: maxDate)
        resultBlock = completion
        show()
    }
    
    // MARK: - Date Logic

    private func buildYearArray() {
        guard componentLayout.contains(.year) else {
            yearArray = []
            return
        }

        let currentYear = yearValue(for: referenceDate)
        var startYear = 1900
        var endYear = currentYear + 50
        if let minDate {
            startYear = min(startYear, yearValue(for: minDate))
            endYear = max(endYear, yearValue(for: minDate))
        }
        if let maxDate {
            startYear = min(startYear, yearValue(for: maxDate))
            endYear = max(endYear, yearValue(for: maxDate))
        }
        startYear = min(startYear, yearValue(for: referenceDate))
        endYear = max(endYear, yearValue(for: referenceDate))
        yearArray = Array(startYear...max(startYear, endYear))
    }

    private func yearValue(for date: Date) -> Int {
        pickerMode == .yw
            ? calendar.component(.yearForWeekOfYear, from: date)
            : calendar.component(.year, from: date)
    }
    
    /// 將 Date 對象拆解為內部選中屬性
    private func updateSelectedValues(from date: Date) {
        self.selectedYear = pickerMode == .yw
            ? calendar.component(.yearForWeekOfYear, from: date)
            : calendar.component(.year, from: date)
        self.selectedMonth = calendar.component(.month, from: date)
        self.selectedDay = calendar.component(.day, from: date)
        self.selectedHour = calendar.component(.hour, from: date)
        self.selectedMinute = calendar.component(.minute, from: date)
        self.selectedSecond = calendar.component(.second, from: date)
        self.selectedQuarter = calendar.component(.quarter, from: date)
        self.selectedWeek = pickerMode == .ymw
            ? calendar.component(.weekOfMonth, from: date)
            : calendar.component(.weekOfYear, from: date)
    }
    
    /// 更新動態天數和周數
    private func updateDynamicArrays() {
        var components = DateComponents()
        components.year = componentLayout.contains(.year)
            ? selectedYear
            : calendar.component(.year, from: referenceDate)
        components.month = componentLayout.contains(.month)
            ? selectedMonth
            : calendar.component(.month, from: referenceDate)
        components.day = 1
        
        guard let date = calendar.date(from: components) else { return }
        
        if componentLayout.contains(.day) {
            if let range = calendar.range(of: .day, in: .month, for: date) {
                dayArray = Array(range)
                selectedDay = min(max(selectedDay, range.lowerBound), range.upperBound)
            }
        }
        
        if componentLayout.contains(.weekOfMonth) {
            if let range = calendar.range(of: .weekOfMonth, in: .month, for: date) {
                weekArray = Array(range)
                selectedWeek = min(max(selectedWeek, range.lowerBound), range.upperBound)
            }
        }
        
        if componentLayout.contains(.weekOfYear) {
            if let range = calendar.range(of: .weekOfYear, in: .yearForWeekOfYear, for: date) {
                weekArray = Array(range)
                selectedWeek = min(max(selectedWeek, range.lowerBound), range.upperBound)
            }
        }
    }
    
    private func selectionDate() -> Date? {
        guard dateIsConfigured, configurationError != .reversedRange else { return nil }

        let hasYear = componentLayout.contains(.year)
        let hasMonth = componentLayout.contains(.month)
        let hasDay = componentLayout.contains(.day)
        let hasHour = componentLayout.contains(.hour)
        let hasMinute = componentLayout.contains(.minute)
        let hasSecond = componentLayout.contains(.second)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: referenceDate)

        if hasYear { components.year = selectedYear }
        if hasMonth { components.month = selectedMonth }
        if hasDay { components.day = selectedDay }
        else if hasMonth || hasYear { components.day = 1 }
        if hasHour { components.hour = selectedHour }
        else if pickerMode != .ms { components.hour = 0 }
        if hasMinute { components.minute = selectedMinute }
        else { components.minute = 0 }
        if hasSecond { components.second = selectedSecond }
        else { components.second = 0 }

        switch pickerMode {
        case .yq:
            let monthRange = calendar.range(of: .month, in: .year, for: referenceDate)
            let firstMonth = (selectedQuarter - 1) * 3 + 1
            guard let monthRange, monthRange.contains(firstMonth) else { return nil }
            components.month = firstMonth
            components.day = 1
            return calendar.date(from: components)
        case .ymw:
            return firstDate(inMonth: selectedMonth, weekOfMonth: selectedWeek, year: selectedYear)
        case .yw:
            var weekComponents = DateComponents()
            weekComponents.calendar = calendar
            weekComponents.timeZone = calendar.timeZone
            weekComponents.yearForWeekOfYear = selectedYear
            weekComponents.weekOfYear = selectedWeek
            weekComponents.weekday = calendar.firstWeekday
            weekComponents.hour = 0
            weekComponents.minute = 0
            weekComponents.second = 0
            return calendar.date(from: weekComponents)
        default:
            return calendar.date(from: components)
        }
    }

    private func firstDate(inMonth month: Int, weekOfMonth week: Int, year: Int) -> Date? {
        var monthComponents = DateComponents()
        monthComponents.year = year
        monthComponents.month = month
        monthComponents.day = 1
        guard let firstDay = calendar.date(from: monthComponents),
              let dayRange = calendar.range(of: .day, in: .month, for: firstDay) else { return nil }

        for day in dayRange {
            var dayComponents = DateComponents()
            dayComponents.year = year
            dayComponents.month = month
            dayComponents.day = day
            guard let date = calendar.date(from: dayComponents) else { continue }
            if calendar.component(.weekOfMonth, from: date) == week { return date }
        }
        return nil
    }

    private func selectionInterval(for date: Date) -> DateInterval? {
        switch pickerMode {
        case .y: return calendar.dateInterval(of: .year, for: date)
        case .ym: return calendar.dateInterval(of: .month, for: date)
        case .yq: return calendar.dateInterval(of: .quarter, for: date)
        case .ymw, .yw: return calendar.dateInterval(of: .weekOfYear, for: date)
        case .ymdh: return calendar.dateInterval(of: .hour, for: date)
        case .ymdhm, .mdhm, .hm: return calendar.dateInterval(of: .minute, for: date)
        case .ymdhms, .hms, .ms: return calendar.dateInterval(of: .second, for: date)
        case .md, .ymd: return calendar.dateInterval(of: .day, for: date)
        }
    }

    private func resolvedSelectedDate() -> Date? {
        guard let candidate = selectionDate() else { return nil }
        guard let minDate, let maxDate else {
            if let minDate, candidate < minDate,
               let interval = selectionInterval(for: candidate), interval.end > minDate { return minDate }
            if let maxDate, candidate > maxDate,
               let interval = selectionInterval(for: candidate), interval.start <= maxDate { return maxDate }
            return candidate
        }
        guard minDate <= maxDate else { return nil }
        if candidate < minDate {
            guard let interval = selectionInterval(for: candidate), interval.end > minDate else { return nil }
            return minDate
        }
        if candidate > maxDate {
            guard let interval = selectionInterval(for: candidate), interval.start <= maxDate else { return nil }
            return maxDate
        }
        return candidate
    }

    private func validateBoundary() {
        guard dateIsConfigured else { return }
        if let minDate, let maxDate, minDate > maxDate {
            configurationError = .reversedRange
            updateConfirmButtonState()
            return
        }

        guard let candidate = selectionDate() else {
            configurationError = .noRepresentableDate
            updateConfirmButtonState()
            return
        }

        var boundaryDate: Date?
        if let minDate, candidate < minDate,
           let interval = selectionInterval(for: candidate), interval.end <= minDate {
            boundaryDate = minDate
        } else if let maxDate, candidate > maxDate,
                  let interval = selectionInterval(for: candidate), interval.start > maxDate {
            boundaryDate = maxDate
        }

        if let boundaryDate {
            updateSelectedValues(from: boundaryDate)
            updateDynamicArrays()
            pickerView.reloadAllComponents()
            scrollToDefaultPosition(animated: true)
        }

        configurationError = resolvedSelectedDate() == nil ? .noRepresentableDate : nil
        updateConfirmButtonState()
    }

    private func updateConfirmButtonState() {
        confirmButton.isEnabled = canConfirm
    }
    
    /// 【修改】支援帶動畫的滾動
    private func scrollToDefaultPosition(animated: Bool) {
        for (componentIndex, type) in componentLayout.enumerated() {
            var targetIndex: Int?
            switch type {
            case .year: targetIndex = yearArray.firstIndex(of: selectedYear)
            case .month: targetIndex = monthArray.firstIndex(of: selectedMonth)
            case .day: targetIndex = dayArray.firstIndex(of: selectedDay)
            case .hour: targetIndex = hourArray.firstIndex(of: selectedHour)
            case .minute: targetIndex = minuteArray.firstIndex(of: selectedMinute)
            case .second: targetIndex = secondArray.firstIndex(of: selectedSecond)
            case .quarter: targetIndex = quarterArray.firstIndex(of: selectedQuarter)
            case .weekOfYear, .weekOfMonth: targetIndex = weekArray.firstIndex(of: selectedWeek)
            }
            
            if let index = targetIndex, index >= 0 {
                pickerView.selectRow(index, inComponent: componentIndex, animated: animated)
            }
        }
    }
    
    private func formattedSelection() -> String {
        switch pickerMode {
        case .ymd: return String(format: "%04d-%02d-%02d", selectedYear, selectedMonth, selectedDay)
        case .ymdhm: return String(format: "%04d-%02d-%02d %02d:%02d", selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute)
        case .hm: return String(format: "%02d:%02d", selectedHour, selectedMinute)
        case .ymdhms: return String(format: "%04d-%02d-%02d %02d:%02d:%02d", selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute, selectedSecond)
        case .ymdh: return String(format: "%04d-%02d-%02d %02d", selectedYear, selectedMonth, selectedDay, selectedHour)
        case .mdhm: return String(format: "%02d-%02d %02d:%02d", selectedMonth, selectedDay, selectedHour, selectedMinute)
        case .ym: return String(format: "%04d-%02d", selectedYear, selectedMonth)
        case .y: return String(format: "%04d", selectedYear)
        case .md: return String(format: "%02d-%02d", selectedMonth, selectedDay)
        case .hms: return String(format: "%02d:%02d:%02d", selectedHour, selectedMinute, selectedSecond)
        case .ms: return String(format: "%02d:%02d", selectedMinute, selectedSecond)
        case .yq: return String(format: "%04d-Q%d", selectedYear, selectedQuarter)
        case .ymw: return String(format: "%04d-%02d-W%d", selectedYear, selectedMonth, selectedWeek)
        case .yw: return String(format: "%04d-W%d", selectedYear, selectedWeek)
        }
    }

    // MARK: - Override Base
    public override func confirmAction() {
        guard canConfirm, let selectedDate = currentSelectedDate else { return }
        let formatString = formattedSelection()
        resultBlock?(selectedDate, formatString)
        super.confirmAction()
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        componentLayout.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard componentLayout.indices.contains(component) else { return 0 }
        let type = componentLayout[component]
        switch type {
        case .year: return yearArray.count
        case .month: return monthArray.count
        case .day: return dayArray.count
        case .hour: return hourArray.count
        case .minute: return minuteArray.count
        case .second: return secondArray.count
        case .quarter: return quarterArray.count
        case .weekOfYear, .weekOfMonth: return weekArray.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerStyle.pickerRowHeight
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        guard componentLayout.indices.contains(component) else {
            return pickerLabel(reusing: view, text: nil)
        }

        let type = componentLayout[component]
        let text: String?
        switch type {
        case .year: text = yearArray.indices.contains(row) ? "\(yearArray[row])" : nil
        case .month: text = monthArray.indices.contains(row) ? String(format: "%02d", monthArray[row]) : nil
        case .day: text = dayArray.indices.contains(row) ? String(format: "%02d", dayArray[row]) : nil
        case .hour: text = hourArray.indices.contains(row) ? String(format: "%02d", hourArray[row]) : nil
        case .minute: text = minuteArray.indices.contains(row) ? String(format: "%02d", minuteArray[row]) : nil
        case .second: text = secondArray.indices.contains(row) ? String(format: "%02d", secondArray[row]) : nil
        case .quarter: text = quarterArray.indices.contains(row) ? "Q\(quarterArray[row])" : nil
        case .weekOfYear, .weekOfMonth: text = weekArray.indices.contains(row) ? "\(weekArray[row])" : nil
        }
        return pickerLabel(reusing: view, text: text)
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard componentLayout.indices.contains(component) else { return }
        let type = componentLayout[component]
        
        // 更新內部選中狀態
        switch type {
        case .year:
            guard yearArray.indices.contains(row) else { return }
            selectedYear = yearArray[row]
        case .month:
            guard monthArray.indices.contains(row) else { return }
            selectedMonth = monthArray[row]
        case .day:
            guard dayArray.indices.contains(row) else { return }
            selectedDay = dayArray[row]
        case .hour:
            guard hourArray.indices.contains(row) else { return }
            selectedHour = hourArray[row]
        case .minute:
            guard minuteArray.indices.contains(row) else { return }
            selectedMinute = minuteArray[row]
        case .second:
            guard secondArray.indices.contains(row) else { return }
            selectedSecond = secondArray[row]
        case .quarter:
            guard quarterArray.indices.contains(row) else { return }
            selectedQuarter = quarterArray[row]
        case .weekOfYear, .weekOfMonth:
            guard weekArray.indices.contains(row) else { return }
            selectedWeek = weekArray[row]
        }
        
        // 聯動刷新天數和周數
        if type == .year || type == .month {
            updateDynamicArrays()
            if let dayIndex = componentLayout.firstIndex(of: .day) { pickerView.reloadComponent(dayIndex) }
            if let weekOfMonthIndex = componentLayout.firstIndex(of: .weekOfMonth) { pickerView.reloadComponent(weekOfMonthIndex) }
            if let weekOfYearIndex = componentLayout.firstIndex(of: .weekOfYear) { pickerView.reloadComponent(weekOfYearIndex) }
        }
        
        // 最後校驗邊界，如果越界會自動動畫回彈！
        validateBoundary()
        updateConfirmButtonState()
        if let selectedDate = currentSelectedDate {
            onSelectionChanged?(selectedDate, formattedSelection())
        }
    }
}

@MainActor
public class PTTreePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    private let pickerView = UIPickerView()
    
    /// 動態維護的列數據：二維數組，每一項代表目前 UI 上顯示的一列數據
    private var currentColumns: [[PTTreePickerModel]] = []
    private var selectedRows: [Int] = []
    
    // MARK: - Current Selection Properties
    /// 获取当前各层级选中的索引数组
    public var selectedIndices: [Int] { selectedRows }
    
    /// 直接获取当前选中的层级结果数组
    public var currentResults: [PTPickerResult] {
        selectedRows.enumerated().compactMap { component, row in
            guard currentColumns.indices.contains(component),
                  currentColumns[component].indices.contains(row) else { return nil }
            let model = currentColumns[component][row]
            return PTPickerResult(index: row, value: model.pickerDisplayText, originalModel: model)
        }
    }

    /// 選擇完成後的回調：返回所有選中的層級結果
    public var resultBlock: ((_ results: [PTPickerResult]) -> Void)?

    /// EN: Emits a stable snapshot after a valid tree selection.
    /// ES: Emite una instantánea estable después de una selección válida.
    /// 中文：树形选择有效后回调稳定的结果快照。
    public var onSelectionChanged: (@MainActor @Sendable ([PTPickerResult]) -> Void)?

    public override var canConfirm: Bool {
        !currentColumns.isEmpty &&
        currentColumns.count == selectedRows.count &&
        currentColumns.enumerated().allSatisfy { component, rows in
            rows.indices.contains(selectedRows[component])
        }
    }
    
    // MARK: - Initialization
    public override init(style: PTPickerStyle? = nil) {
        super.init(style: style)
        self.setupPicker()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPicker()
    }
        
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPicker()
    }
    
    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerContainer.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    /// EN: Configures the tree without presenting the picker.
    /// ES: Configura el árbol sin presentar el selector.
    /// 中文：只配置树形数据，不展示 Picker。
    public func configure(title: String, treeData: [PTTreePickerModel], defaultIndices: [Int]? = nil) {
        titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        resultBlock = nil
        buildInitialColumns(from: treeData, defaultIndices: defaultIndices)
        pickerView.reloadAllComponents()
        restorePickerSelection()
        updateConfirmButtonState()
    }

    public func show(title: String, treeData: [PTTreePickerModel], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) {
        configure(title: title, treeData: treeData, defaultIndices: defaultIndices)
        resultBlock = completion
        show()
    }

    /// EN: Selects a row and rebuilds only the affected descendant path.
    /// ES: Selecciona una fila y reconstruye solo la ruta descendiente afectada.
    /// 中文：选择一行，只重建受影响的子级路径。
    public func selectRow(_ row: Int, inComponent component: Int, animated: Bool = false, notifySelectionChanged: Bool = true) {
        guard currentColumns.indices.contains(component), !currentColumns[component].isEmpty else { return }
        let safeRow = min(max(row, 0), currentColumns[component].count - 1)
        pickerView.selectRow(safeRow, inComponent: component, animated: animated)
        updateSelection(safeRow, inComponent: component, notifySelectionChanged: notifySelectionChanged)
    }
    
    // MARK: - Tree Logic (核心樹狀算法)
    
    /// 構建初始的列數據
    private func buildInitialColumns(from rootData: [PTTreePickerModel], defaultIndices: [Int]?) {
        currentColumns = []
        selectedRows = []
        var currentLevel = rootData
        var colIndex = 0

        while !currentLevel.isEmpty {
            currentColumns.append(currentLevel)
            let requestedRow = defaultIndices.flatMap { $0.indices.contains(colIndex) ? $0[colIndex] : nil } ?? 0
            let safeRow = min(max(requestedRow, 0), currentLevel.count - 1)
            selectedRows.append(safeRow)
            currentLevel = currentLevel[safeRow].pickerChildren
            colIndex += 1
        }
    }
    
    private func restorePickerSelection() {
        for component in currentColumns.indices {
            pickerView.selectRow(selectedRows[component], inComponent: component, animated: false)
        }
    }

    private func updateSelection(_ row: Int, inComponent component: Int, notifySelectionChanged: Bool) {
        guard currentColumns.indices.contains(component),
              currentColumns[component].indices.contains(row) else { return }

        let oldComponentCount = currentColumns.count
        selectedRows[component] = row
        if currentColumns.count > component + 1 {
            currentColumns.removeSubrange((component + 1)..<currentColumns.count)
            selectedRows.removeSubrange((component + 1)..<selectedRows.count)
        }

        var nextChildren = currentColumns[component][row].pickerChildren
        while !nextChildren.isEmpty {
            currentColumns.append(nextChildren)
            selectedRows.append(0)
            nextChildren = nextChildren[0].pickerChildren
        }

        if oldComponentCount != currentColumns.count {
            pickerView.reloadAllComponents()
            restorePickerSelection()
        } else if component + 1 < currentColumns.count {
            for affectedComponent in (component + 1)..<currentColumns.count {
                pickerView.reloadComponent(affectedComponent)
                pickerView.selectRow(selectedRows[affectedComponent],
                                     inComponent: affectedComponent,
                                     animated: true)
            }
        }

        updateConfirmButtonState()
        if notifySelectionChanged { onSelectionChanged?(currentResults) }
    }

    private func updateConfirmButtonState() {
        confirmButton.isEnabled = canConfirm
    }

    // MARK: - Override Base
    public override func confirmAction() {
        guard canConfirm else { return }
        resultBlock?(currentResults)
        super.confirmAction()
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return currentColumns.count // 動態列數！(可能是2列，也可能是3列)
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        currentColumns.indices.contains(component) ? currentColumns[component].count : 0
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerStyle.pickerRowHeight
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let text = currentColumns.indices.contains(component) && currentColumns[component].indices.contains(row)
            ? currentColumns[component][row].pickerDisplayText
            : nil
        return pickerLabel(reusing: view, text: text)
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateSelection(row, inComponent: component, notifySelectionChanged: true)
    }
}
