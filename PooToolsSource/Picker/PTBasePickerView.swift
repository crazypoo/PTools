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
    
    public var pickerBackgroundColor:UIColor = .white
    
    public var toolBarTopBottomSpacing:CGFloat = 2.5
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
    
    public let titleLabel = UIButton(type: .custom)
    public let cancelButton = UIButton(type: .custom)
    public let confirmButton = UIButton(type: .custom)
    
    // MARK: - Properties
    private let containerHeight: CGFloat = 300.0
    private let toolbarHeight: CGFloat = 50.0
    
    public var pickerStyle: PTPickerStyle!
    
    public init(style: PTPickerStyle? = nil) {
        self.pickerStyle = style ?? PTPickerStyle.shared
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }

    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // 设置半透明背景
        containerView.backgroundColor = pickerStyle.containerBackgroundColor
        if #available(iOS 26.0, *) {
            toolbarView.backgroundColor = .clear
        } else {
            toolbarView.backgroundColor = pickerStyle.toolbarBackgroundColor
        }

        backgroundView.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        backgroundView.addGestureRecognizer(tapGesture)
        addSubviews([backgroundView,containerView])
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 设置容器视图 (初始位置在屏幕下方，为了做动画)
        // 切圆角
        containerView.layer.cornerRadius = 16
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(self.containerHeight)
            make.height.equalTo(self.containerHeight)
        }
        
        // 设置工具栏
        containerView.addSubview(toolbarView)
        toolbarView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(self.toolbarHeight)
        }
        
        var buttonClearGlassOffset:CGFloat = 5
        if #available(iOS 26.0, *) {
            cancelButton.configuration = UIButton.Configuration.clearGlass()
            confirmButton.configuration = UIButton.Configuration.clearGlass()
            titleLabel.configuration = UIButton.Configuration.clearGlass()
            buttonClearGlassOffset += 25
        }

        // 配置按钮和标题
        cancelButton.titleLabel?.font = pickerStyle.cancelTextFont
        cancelButton.titleLabel?.numberOfLines = 1
        cancelButton.setTitle(pickerStyle.cancelText, for: .normal)
        cancelButton.setTitleColor(pickerStyle.cancelTextColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        let cancelW = self.cancelButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        
        confirmButton.titleLabel?.font = pickerStyle.confirmTextFont
        confirmButton.titleLabel?.numberOfLines = 1
        confirmButton.setTitle(pickerStyle.confirmText, for: .normal)
        confirmButton.setTitleColor(pickerStyle.confirmTextColor, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        let confirmW = self.confirmButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        
        titleLabel.isUserInteractionEnabled = false
        titleLabel.isHidden = true
        titleLabel.setTitleColor(pickerStyle.titleTextColor, for: .normal)
        titleLabel.titleLabel?.font = pickerStyle.titleTextFont
        titleLabel.titleLabel?.textAlignment = .center
        toolbarView.addSubviews([cancelButton,confirmButton,titleLabel])
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
            make.width.equalTo(0)
        }
    }
    
    public func resetTitleLabelwidth() {
        var buttonClearGlassOffset:CGFloat = 5
        if #available(iOS 26.0, *) {
            buttonClearGlassOffset += 25
        }
        let cancelW = self.cancelButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        let confirmW = self.confirmButton.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset

        let titleMax = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 3 - cancelW - confirmW
        var titleW = self.titleLabel.sizeFor(height: self.toolbarHeight - self.pickerStyle.toolBarTopBottomSpacing * 2).width + buttonClearGlassOffset
        if titleW > titleMax {
            titleW = titleMax
        }
        titleLabel.snp.updateConstraints { make in
            make.width.equalTo(titleW)
        }
        
        titleLabel.isHidden = (titleLabel.currentTitle ?? "").stringIsEmpty()
    }
    
    // MARK: - Actions
    /// 子类需重写此方法以处理确定逻辑
    @objc open func confirmAction() {
        dismiss()
    }
    
    // MARK: - Animations
    public func show() {
        // 寻找当前活跃的 Window 添加视图
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        window.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 强制立即刷新初始布局，确保起始位置正确
        self.layoutIfNeeded()
        
        // 更新为目标位置的约束
        self.containerView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(0)
        }
        
        // 执行动画
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.backgroundView.alpha = 1
            // 在动画闭包内调用 layoutIfNeeded() 来触发约束改变的平滑动画
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc public func dismiss() {
        // 更新为隐藏位置的约束
        self.containerView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(self.containerHeight)
        }
        
        // 执行动画
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.backgroundView.alpha = 0
            // 在动画闭包内调用 layoutIfNeeded()
            self.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

@MainActor
public class PTStringPickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    private let pickerView = UIPickerView()
    
    // 底层数据源统一升级为二维数组
    private var dataSource: [[PTPickerStringModel]] = []
    
    // MARK: - Current Selection Properties
    /// 获取当前选中的索引（单列场景使用）
    public var selectedIndex: Int {
        return pickerView.selectedRow(inComponent: 0)
    }
    
    /// 获取当前选中的索引数组（多列场景使用）
    public var selectedIndices: [Int] {
        var indices: [Int] = []
        for component in 0..<dataSource.count {
            indices.append(pickerView.selectedRow(inComponent: component))
        }
        return indices
    }
    
    /// 直接获取当前选中的完整结果数组（附带 Model）
    public var currentResults: [PTPickerResult] {
        var results: [PTPickerResult] = []
        for component in 0..<dataSource.count {
            let row = pickerView.selectedRow(inComponent: component)
            if row >= 0 && row < dataSource[component].count {
                let model = dataSource[component][row]
                results.append(PTPickerResult(index: row, value: model.pickerDisplayText, originalModel: model))
            }
        }
        return results
    }

    // 区分单列和多列的回调
    public var singleResultBlock: ((_ result: PTPickerResult) -> Void)?
    public var multiResultBlock: ((_ results: [PTPickerResult]) -> Void)?

    public override init(style: PTPickerStyle? = nil) {
        super.init(style: style)
        self.setupPicker()
    }
        
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerView.backgroundColor = pickerStyle.pickerBackgroundColor
        containerView.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.toolbarView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods (方法重载)
    /// 配置并显示【单列】数据
    public func show(title: String, data: [PTPickerStringModel], defaultIndex: Int = 0, completion: @escaping (PTPickerResult) -> Void) {
        self.titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        self.dataSource = [data]
        self.singleResultBlock = completion
        self.multiResultBlock = nil
        
        pickerView.reloadAllComponents()
        
        if defaultIndex < data.count && defaultIndex >= 0 {
            pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
        }
        
        self.show()
    }

    /// 配置并显示【多列】数据
    public func show(title: String, multiData: [[PTPickerStringModel]], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) {
        self.titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        self.dataSource = multiData
        self.multiResultBlock = completion
        self.singleResultBlock = nil
        
        pickerView.reloadAllComponents()
        
        if let indices = defaultIndices, indices.count == multiData.count {
            for (component, index) in indices.enumerated() {
                if index >= 0 && index < multiData[component].count {
                    pickerView.selectRow(index, inComponent: component, animated: false)
                }
            }
        }
        
        self.show()
    }

    // MARK: - Override Base
    public override func confirmAction() {
        var results: [PTPickerResult] = []
        
        for component in 0..<dataSource.count {
            let row = pickerView.selectedRow(inComponent: component)
            if row >= 0 && row < dataSource[component].count {
                // 【修改 3】取出 Model，構建強大的 Result
                let model = dataSource[component][row]
                let result = PTPickerResult(index: row, value: model.pickerDisplayText, originalModel: model)
                results.append(result)
            }
        }
        
        if let singleBlock = singleResultBlock, let firstResult = results.first {
            singleBlock(firstResult)
        } else if let multiBlock = multiResultBlock {
            multiBlock(results)
        }
        
        super.confirmAction()
    }

    // MARK: - UIPickerView DataSource & Delegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return dataSource.count // 动态返回列数
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource[component].count // 动态返回对应列的行数
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerStyle.pickerRowHeight
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            
        let label = (view as? UILabel) ?? UILabel()
        
        label.textAlignment = .center
        label.textColor = pickerStyle.pickerTextColor
        label.font = pickerStyle.pickerTextFont
        label.backgroundColor = .clear
        
        // 取出对应列、对应行的数据
        label.text = dataSource[component][row].pickerDisplayText
        return label
    }
}

@MainActor
public class PTDatePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    private let pickerView = UIPickerView()
    private var pickerMode: PTDatePickerMode = .ymd
    
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
    
    // MARK: - Current Selection Properties
    /// 实时获取当前选中的日期对象
    public var currentSelectedDate: Date? {
        var components = DateComponents()
        // 设置默认兜底值
        components.year = Calendar.current.component(.year, from: Date())
        components.month = 1; components.day = 1; components.hour = 0; components.minute = 0; components.second = 0
        
        switch pickerMode {
        case .ymd:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay
        case .ymdhm:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour; components.minute = selectedMinute
        case .hm:
            components.hour = selectedHour; components.minute = selectedMinute
        case .ymdhms:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour; components.minute = selectedMinute; components.second = selectedSecond
        case .ymdh:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour
        case .mdhm:
            components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour; components.minute = selectedMinute
        case .ym:
            components.year = selectedYear; components.month = selectedMonth
        case .y:
            components.year = selectedYear
        case .md:
            components.month = selectedMonth; components.day = selectedDay
        case .hms:
            components.hour = selectedHour; components.minute = selectedMinute; components.second = selectedSecond
        case .ms:
            components.minute = selectedMinute; components.second = selectedSecond
        case .yq:
            components.year = selectedYear; components.quarter = selectedQuarter
        case .ymw:
            components.year = selectedYear; components.month = selectedMonth; components.weekOfMonth = selectedWeek
        case .yw:
            components.year = selectedYear; components.weekOfYear = selectedWeek
        }
        
        return Calendar.current.date(from: components)
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
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerView.backgroundColor = pickerStyle.pickerBackgroundColor
        containerView.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.toolbarView.snp.bottom)
            make.bottom.equalToSuperview()
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
    /// 【修改】支援傳入 minDate 和 maxDate
    public func show(title: String,
                     mode: PTDatePickerMode = .ymd,
                     defaultDate: Date = Date(),
                     minDate: Date? = nil,
                     maxDate: Date? = nil,
                     completion: @escaping (Date, String) -> Void) {
        
        self.titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        self.pickerMode = mode
        self.minDate = minDate
        self.maxDate = maxDate
        self.resultBlock = completion
        
        let calendar = Calendar.current
        
        // 1. 動態構建年份數據源 (根據邊界自動縮放)
        let defaultMinYear = 1900
        let defaultMaxYear = calendar.component(.year, from: Date()) + 50
        let startYear = minDate != nil ? calendar.component(.year, from: minDate!) : defaultMinYear
        let endYear = maxDate != nil ? calendar.component(.year, from: maxDate!) : defaultMaxYear
        self.yearArray = Array(startYear...max(startYear, endYear))
        
        // 2. 解析默認日期 (提取到專門的函數)
        updateSelectedValues(from: defaultDate)
        
        // 3. 校驗默認日期是否越界
        validateBoundary()
        
        // 4. 初始化天數/周數
        updateDynamicArrays()
        
        // 5. 刷新並展示
        pickerView.reloadAllComponents()
        scrollToDefaultPosition(animated: false)
        
        self.show()
    }
    
    // MARK: - Date Logic
    
    /// 將 Date 對象拆解為內部選中屬性
    private func updateSelectedValues(from date: Date) {
        let calendar = Calendar.current
        self.selectedYear = calendar.component(.year, from: date)
        self.selectedMonth = calendar.component(.month, from: date)
        self.selectedDay = calendar.component(.day, from: date)
        self.selectedHour = calendar.component(.hour, from: date)
        self.selectedMinute = calendar.component(.minute, from: date)
        self.selectedSecond = calendar.component(.second, from: date)
        self.selectedQuarter = calendar.component(.quarter, from: date)
        self.selectedWeek = (pickerMode == .ymw) ? calendar.component(.weekOfMonth, from: date) : calendar.component(.weekOfYear, from: date)
    }
    
    /// 更新動態天數和周數
    private func updateDynamicArrays() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = (pickerMode == .md || pickerMode == .mdhm) ? 2000 : selectedYear
        components.month = selectedMonth
        
        guard let date = calendar.date(from: components) else { return }
        
        if componentLayout.contains(.day) {
            if let range = calendar.range(of: .day, in: .month, for: date) {
                dayArray = Array(range)
                if selectedDay > dayArray.count { selectedDay = dayArray.count }
            }
        }
        
        if componentLayout.contains(.weekOfMonth) {
            if let range = calendar.range(of: .weekOfMonth, in: .month, for: date) {
                weekArray = Array(range)
                if selectedWeek > weekArray.count { selectedWeek = weekArray.count }
            }
        }
        
        if componentLayout.contains(.weekOfYear) {
            if let range = calendar.range(of: .weekOfYear, in: .year, for: date) {
                weekArray = Array(range)
                if selectedWeek > weekArray.count { selectedWeek = weekArray.count }
            }
        }
    }
    
    /// 【核心新增】越界校驗與回彈引擎
    private func validateBoundary() {
        guard minDate != nil || maxDate != nil else { return }
        
        var components = DateComponents()
        let calendar = Calendar.current
        
        // 構造用戶當前選擇的 Date（缺少的組件用安全默認值填補）
        components.year = componentLayout.contains(.year) ? selectedYear : calendar.component(.year, from: Date())
        components.month = componentLayout.contains(.month) ? selectedMonth : 1
        components.day = componentLayout.contains(.day) ? selectedDay : 1
        components.hour = componentLayout.contains(.hour) ? selectedHour : 0
        components.minute = componentLayout.contains(.minute) ? selectedMinute : 0
        components.second = componentLayout.contains(.second) ? selectedSecond : 0
        
        guard let currentSelectedDate = calendar.date(from: components) else { return }
        
        var needSnapBack = false
        
        // 校驗最小日期
        if let min = minDate, currentSelectedDate < min {
            updateSelectedValues(from: min)
            needSnapBack = true
        }
        // 校驗最大日期
        else if let max = maxDate, currentSelectedDate > max {
            updateSelectedValues(from: max)
            needSnapBack = true
        }
        
        // 如果越界，觸發自動回彈修復
        if needSnapBack {
            updateDynamicArrays()
            pickerView.reloadAllComponents()
            // 帶動畫滾動回邊界
            scrollToDefaultPosition(animated: true)
        }
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
    
    // MARK: - Override Base (結果構造保持不變)
    public override func confirmAction() {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())
        components.month = 1; components.day = 1; components.hour = 0; components.minute = 0; components.second = 0
        var formatString = ""
        
        switch pickerMode {
        case .ymd:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay
            formatString = String(format: "%04d-%02d-%02d", selectedYear, selectedMonth, selectedDay)
        case .ymdhm:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay
            components.hour = selectedHour; components.minute = selectedMinute
            formatString = String(format: "%04d-%02d-%02d %02d:%02d", selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute)
        case .hm:
            components.hour = selectedHour; components.minute = selectedMinute
            formatString = String(format: "%02d:%02d", selectedHour, selectedMinute)
        case .ymdhms:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay
            components.hour = selectedHour; components.minute = selectedMinute; components.second = selectedSecond
            formatString = String(format: "%04d-%02d-%02d %02d:%02d:%02d", selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute, selectedSecond)
        case .ymdh:
            components.year = selectedYear; components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour
            formatString = String(format: "%04d-%02d-%02d %02d", selectedYear, selectedMonth, selectedDay, selectedHour)
        case .mdhm:
            components.month = selectedMonth; components.day = selectedDay; components.hour = selectedHour; components.minute = selectedMinute
            formatString = String(format: "%02d-%02d %02d:%02d", selectedMonth, selectedDay, selectedHour, selectedMinute)
        case .ym:
            components.year = selectedYear; components.month = selectedMonth
            formatString = String(format: "%04d-%02d", selectedYear, selectedMonth)
        case .y:
            components.year = selectedYear
            formatString = String(format: "%04d", selectedYear)
        case .md:
            components.month = selectedMonth; components.day = selectedDay
            formatString = String(format: "%02d-%02d", selectedMonth, selectedDay)
        case .hms:
            components.hour = selectedHour; components.minute = selectedMinute; components.second = selectedSecond
            formatString = String(format: "%02d:%02d:%02d", selectedHour, selectedMinute, selectedSecond)
        case .ms:
            components.minute = selectedMinute; components.second = selectedSecond
            formatString = String(format: "%02d:%02d", selectedMinute, selectedSecond)
        case .yq:
            components.year = selectedYear; components.quarter = selectedQuarter
            formatString = String(format: "%04d-Q%d", selectedYear, selectedQuarter)
        case .ymw:
            components.year = selectedYear; components.month = selectedMonth; components.weekOfMonth = selectedWeek
            formatString = String(format: "%04d-%02d-W%d", selectedYear, selectedMonth, selectedWeek)
        case .yw:
            components.year = selectedYear; components.weekOfYear = selectedWeek
            formatString = String(format: "%04d-W%d", selectedYear, selectedWeek)
        }
        
        if let selectedDate = Calendar.current.date(from: components) {
            resultBlock?(selectedDate, formatString)
        }
        super.confirmAction()
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return componentLayout.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
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
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.textColor = pickerStyle.pickerTextColor
        label.font = pickerStyle.pickerTextFont
        label.backgroundColor = .clear
        
        let type = componentLayout[component]
        switch type {
        case .year: label.text = "\(yearArray[row])"
        case .month: label.text = String(format: "%02d", monthArray[row])
        case .day: label.text = String(format: "%02d", dayArray[row])
        case .hour: label.text = String(format: "%02d", hourArray[row])
        case .minute: label.text = String(format: "%02d", minuteArray[row])
        case .second: label.text = String(format: "%02d", secondArray[row])
        case .quarter: label.text = "Q\(quarterArray[row])"
        case .weekOfYear, .weekOfMonth: label.text = "\(weekArray[row])"
        }
        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let type = componentLayout[component]
        
        // 更新內部選中狀態
        switch type {
        case .year: selectedYear = yearArray[row]
        case .month: selectedMonth = monthArray[row]
        case .day: selectedDay = dayArray[row]
        case .hour: selectedHour = hourArray[row]
        case .minute: selectedMinute = minuteArray[row]
        case .second: selectedSecond = secondArray[row]
        case .quarter: selectedQuarter = quarterArray[row]
        case .weekOfYear, .weekOfMonth: selectedWeek = weekArray[row]
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
    }
}

@MainActor
public class PTTreePickerView: PTBasePickerView, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    private let pickerView = UIPickerView()
    
    /// 動態維護的列數據：二維數組，每一項代表目前 UI 上顯示的一列數據
    private var currentColumns: [[PTTreePickerModel]] = []
    
    // MARK: - Current Selection Properties
    /// 获取当前各层级选中的索引数组
    public var selectedIndices: [Int] {
        var indices: [Int] = []
        for component in 0..<currentColumns.count {
            indices.append(pickerView.selectedRow(inComponent: component))
        }
        return indices
    }
    
    /// 直接获取当前选中的层级结果数组
    public var currentResults: [PTPickerResult] {
        var results: [PTPickerResult] = []
        for col in 0..<currentColumns.count {
            let row = pickerView.selectedRow(inComponent: col)
            let levelData = currentColumns[col]
            let safeRow = max(0, min(row, levelData.count - 1))
            
            let model = levelData[safeRow]
            results.append(PTPickerResult(index: safeRow, value: model.pickerDisplayText, originalModel: model))
        }
        return results
    }

    /// 選擇完成後的回調：返回所有選中的層級結果
    public var resultBlock: ((_ results: [PTPickerResult]) -> Void)?
    
    // MARK: - Initialization
    public override init(style: PTPickerStyle? = nil) {
        super.init(style: style)
        self.setupPicker()
    }
        
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPicker() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        pickerView.backgroundColor = pickerStyle.pickerBackgroundColor
        containerView.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.toolbarView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    /// 顯示樹狀聯動選擇器
    /// - Parameters:
    ///   - title: 標題
    ///   - data: 根節點數據數組
    ///   - defaultIndices: 各層級的默認選中索引，例如 [0, 1, 0]
    ///   - completion: 完成回調
    public func show(title: String, treeData: [PTTreePickerModel], defaultIndices: [Int]? = nil, completion: @escaping ([PTPickerResult]) -> Void) {
        self.titleLabel.setTitle(title, for: .normal)
        resetTitleLabelwidth()
        self.resultBlock = completion
        
        // 1. 根據傳入的數據和默認索引，計算出初始需要展示的所有列
        buildInitialColumns(from: treeData, defaultIndices: defaultIndices)
        
        // 2. 刷新選擇器
        pickerView.reloadAllComponents()
        
        // 3. 將滾輪撥動到對應的位置
        for (col, levelData) in currentColumns.enumerated() {
            let defaultRow = (defaultIndices != nil && col < defaultIndices!.count) ? defaultIndices![col] : 0
            let safeRow = max(0, min(defaultRow, levelData.count - 1))
            pickerView.selectRow(safeRow, inComponent: col, animated: false)
        }
        
        self.show()
    }
    
    // MARK: - Tree Logic (核心樹狀算法)
    
    /// 構建初始的列數據
    private func buildInitialColumns(from rootData: [PTTreePickerModel], defaultIndices: [Int]?) {
        currentColumns = [rootData]
        var currentLevel = rootData
        var colIndex = 0
        
        // 遞迴向下尋找子節點，直到葉子節點為止
        while !currentLevel.isEmpty {
            // 獲取當前層應該選中的 index
            let defaultRow = (defaultIndices != nil && colIndex < defaultIndices!.count) ? defaultIndices![colIndex] : 0
            let safeRow = max(0, min(defaultRow, currentLevel.count - 1))
            
            // 如果安全，則取出它的子節點
            if safeRow < currentLevel.count {
                let children = currentLevel[safeRow].pickerChildren
                if !children.isEmpty {
                    currentColumns.append(children)
                }
                currentLevel = children
            } else {
                break
            }
            colIndex += 1
        }
    }
    
    // MARK: - Override Base
    public override func confirmAction() {
        var results: [PTPickerResult] = []
        
        // 遍歷當前渲染出的每一列，收集結果
        for col in 0..<currentColumns.count {
            let row = pickerView.selectedRow(inComponent: col)
            let levelData = currentColumns[col]
            let safeRow = max(0, min(row, levelData.count - 1))
            
            let model = levelData[safeRow]
            let result = PTPickerResult(index: safeRow, value: model.pickerDisplayText, originalModel: model)
            results.append(result)
        }
        
        resultBlock?(results)
        super.confirmAction()
    }
    
    // MARK: - UIPickerView DataSource & Delegate
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return currentColumns.count // 動態列數！(可能是2列，也可能是3列)
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currentColumns[component].count
    }
    
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerStyle.pickerRowHeight
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.textAlignment = .center
        label.textColor = pickerStyle.pickerTextColor
        label.font = pickerStyle.pickerTextFont
        label.backgroundColor = .clear
        
        label.text = currentColumns[component][row].pickerDisplayText
        return label
    }
    
    // 【核心動態聯動邏輯】
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let oldComponentCount = currentColumns.count
        
        // 截斷：刪除當前撥動列「之後」的所有舊數據
        currentColumns.removeSubrange((component + 1)...)
        
        // 獲取當前剛選中的模型
        let currentLevel = currentColumns[component]
        let safeRow = max(0, min(row, currentLevel.count - 1))
        var nextChildren = currentLevel[safeRow].pickerChildren
        
        // 遞迴構建：根據新選中的模型，一路往下尋找默認的第一個子節點，重構右側列
        while !nextChildren.isEmpty {
            currentColumns.append(nextChildren)
            nextChildren = nextChildren[0].pickerChildren // 聯動時，子列默認選中第 0 項
        }
        
        // UI 刷新優化
        if oldComponentCount != currentColumns.count {
            // 如果深度改變了（例如從3級聯動變成了2級），必須刷新整個選擇器以重建列
            pickerView.reloadAllComponents()
        } else {
            // 深度沒變，只需要刷新被影響的右側列，並用動畫將它們滾回到頂部
            for c in (component + 1)..<currentColumns.count {
                pickerView.reloadComponent(c)
                pickerView.selectRow(0, inComponent: c, animated: true)
            }
        }
    }
}
