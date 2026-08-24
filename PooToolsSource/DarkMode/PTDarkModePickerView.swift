//
//  PTDarkModePickerView.swift
//  PTNetworkTesting
//
//  Created by 邓杰豪 on 7/3/23.
//

import UIKit
import SwifterSwift
import SnapKit

// MARK: - 暗黑模式时间的设置
@MainActor
class PTDarkModePickerView: UIView {

    let navBarHeight: CGFloat = 44
    let lineViewHeight: CGFloat = 1.0 / UIScreen.main.scale

    /// 确定时间段的返回。
    var sureClosure: (String, String) -> Void
    /// 开始时间。
    private var startTime: String
    /// 结束时间。
    private var endTime: String
    /// 选择器中的标准时间。
    lazy var timeDataArray: [String] = {
        (0..<24).map { String(format: "%02d:00", $0) }
    }()

    private var isPresented = false
    private var isDismissing = false

    /// 覆盖层，只负责接收空白区域点击。
    private lazy var backdropView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.48)
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
        view.addGestureRecognizer(tap)
        return view
    }()

    /// 时间选择器。
    lazy var leftTimePickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = .flexibleWidth
        return pickerView
    }()

    /// 时间选择器。
    lazy var rightTimePickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = .flexibleWidth
        return pickerView
    }()

    /// 至。
    lazy var middeleLabel: UILabel = {
        let label = UILabel()
        label.text = "~"
        label.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        label.textAlignment = .center
        return label
    }()

    /// 视图的父视图。
    lazy var bgView: UIView = {
        let view = UIView()
        if #available(iOS 26.0, *) {
            view.backgroundColor = .clear
        } else {
            view.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        }
        return view
    }()

    /// 取消。
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(PTDarkModeOption.pickerCancel, for: .normal)
        button.titleLabel?.font = PTDarkModeOption.pickerFont
        button.setTitleColor(.systemBlue, for: .normal)
        button.addActionHandlers { [weak self] _ in
            self?.dismissView()
        }
        let titleWidth = button.sizeFor().width + 16
        var itemHeight: CGFloat = 34
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
            itemHeight = navBarHeight
        }
        button.bounds = CGRect(origin: .zero, size: CGSize(width: titleWidth, height: itemHeight))
        return button
    }()

    /// 确定。
    lazy var sureButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(PTDarkModeOption.pickerDone, for: .normal)
        button.titleLabel?.font = PTDarkModeOption.pickerFont
        button.setTitleColor(.systemBlue, for: .normal)
        button.addActionHandlers { [weak self] _ in
            self?.sureButtonClick()
        }
        let titleWidth = button.sizeFor().width + 16
        var itemHeight: CGFloat = 34
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
            itemHeight = navBarHeight
        }
        button.bounds = CGRect(origin: .zero, size: CGSize(width: titleWidth, height: itemHeight))
        return button
    }()

    /// 顶部的横线。
    lazy var topLineView: UIView = {
        let line = UIView()
        line.backgroundColor = .gray
        return line
    }()

    lazy var topToolBar: PTNavBar = {
        let view = PTNavBar()
        view.isFakeNav = true
        return view
    }()

    init(startTime: String, endTime: String, complete: @escaping (String, String) -> Void) {
        self.startTime = Self.normalizedTime(startTime)
        self.endTime = Self.normalizedTime(endTime)
        sureClosure = complete
        super.init(frame: .zero)
        initUI()
        updatePickerSelection()
    }

    /// 将旧版本可能保存的 8:00、24:00 统一为选择器使用的格式。
    private static func normalizedTime(_ value: String) -> String {
        let components = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              minute >= 0,
              minute <= 59 else {
            return "00:00"
        }

        let normalizedHour = hour == 24 && minute == 0 ? 0 : hour
        guard normalizedHour >= 0, normalizedHour <= 23 else { return "00:00" }
        return String(format: "%02d:%02d", normalizedHour, minute)
    }

    /// 创建控件。
    private func initUI() {
        isAccessibilityElement = false
        accessibilityViewIsModal = true
        backdropView.isAccessibilityElement = false
        addSubview(backdropView)
        addSubview(bgView)

        backdropView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bgView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kPickerHeight + navBarHeight)
        }

        bgView.addSubviews([topToolBar, leftTimePickerView, rightTimePickerView, middeleLabel, topLineView])
        topToolBar.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(navBarHeight)
        }

        topToolBar.setLeftButtons([cancelButton])
        topToolBar.setRightButtons([sureButton])

        leftTimePickerView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.right.equalTo(bgView.snp.centerX)
            make.top.equalTo(topToolBar.snp.bottom)
        }

        rightTimePickerView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(bgView.snp.centerX)
            make.top.equalTo(leftTimePickerView)
        }

        middeleLabel.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.centerX.equalToSuperview()
            make.centerY.equalTo(leftTimePickerView)
        }

        topLineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topToolBar.snp.bottom).offset((-lineViewHeight) / 2)
            make.height.equalTo(lineViewHeight)
        }

        bgView.viewCornerRectCorner(
            topLeft: PTDarkModeOption.timeRangePickerCornerRadius,
            topRight: PTDarkModeOption.timeRangePickerCornerRadius,
            corner: [.topLeft, .topRight]
        )
    }

    private func updatePickerSelection() {
        guard let startIndex = timeDataArray.firstIndex(of: startTime),
              let endIndex = timeDataArray.firstIndex(of: endTime) else {
            return
        }
        leftTimePickerView.selectRow(startIndex, inComponent: 0, animated: false)
        rightTimePickerView.selectRow(endIndex, inComponent: 0, animated: false)
    }

    private func activeWindow() -> UIWindow? {
        PTUtils.fetchWindow() ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState != .background })?
            .windows
            .first(where: { $0.isKeyWindow })
    }

    // MARK: - 弹出时间
    func showTime() {
        guard !isPresented, !isDismissing, let window = activeWindow() else { return }

        isPresented = true
        translatesAutoresizingMaskIntoConstraints = true
        frame = window.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(self)
        layoutIfNeeded()

        bgView.transform = CGAffineTransform(translationX: 0, y: bgView.bounds.height)
        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseOut]) { [weak self] in
            self?.bgView.transform = .identity
        }
    }

    @objc private func backdropTapped() {
        dismissView()
    }

    // MARK: - 界面消失
    @objc private func dismissView() {
        guard isPresented, !isDismissing else { return }
        isDismissing = true

        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseIn]) { [weak self] in
            guard let self else { return }
            self.bgView.transform = CGAffineTransform(translationX: 0, y: self.bgView.bounds.height)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
            self.isPresented = false
            self.isDismissing = false
            self.bgView.transform = .identity
        }
    }

    // MARK: - 确定
    @objc private func sureButtonClick() {
        guard isPresented, !isDismissing else { return }
        isDismissing = true
        sureClosure(startTime, endTime)

        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.beginFromCurrentState, .curveEaseIn]) { [weak self] in
            guard let self else { return }
            self.bgView.transform = CGAffineTransform(translationX: 0, y: self.bgView.bounds.height)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.removeFromSuperview()
            self.isPresented = false
            self.isDismissing = false
            self.bgView.transform = .identity
        }
    }

    required init?(coder: NSCoder) {
        fatalError("不支持从 NSCoder 创建时间选择器")
    }
}

extension PTDarkModePickerView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        timeDataArray.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        47
    }

    func pickerView(_ pickerView: UIPickerView,
                    viewForRow row: Int,
                    forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = PTDarkModeOption.pickerLabelFont
        label.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        label.textAlignment = .center
        label.text = timeDataArray.indices.contains(row) ? timeDataArray[row] : nil
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard timeDataArray.indices.contains(row) else { return }
        if pickerView === leftTimePickerView {
            startTime = timeDataArray[row]
        } else if pickerView === rightTimePickerView {
            endTime = timeDataArray[row]
        }
    }
}
