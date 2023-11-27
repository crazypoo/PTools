//
//  PTDarkModePickerView.swift
//  PTNetworkTesting
//
//  Created by 邓杰豪 on 7/3/23.
//

// MARK: - 暗黑模式时间的设置
import UIKit
import SwifterSwift

class PTDarkModePickerView: UIView {
    /// 确定时间段的返回
    var sureClosure: (String, String)->Void
    /// 开始时间
    private var startTime = "21:00"
    /// 结束时间
    private var endTime = "8:00"
    /// 时间数组
    lazy var timeDataArray: [String] = {
        let array = ["00:00", "01:00", "02:00", "03:00", "04:00", "05:00", "06:00", "07:00", "8:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00", "24:00"]
        return array
    }()
    /// 时间选择器
    lazy var leftTimePickerView: UIPickerView = {
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 44, width: UIScreen.main.bounds.width / 2.0, height: 200))
        pickerView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = .flexibleWidth
        let index = timeDataArray.firstIndex(of: startTime) ?? 0
        pickerView.selectRow(index, inComponent: 0, animated: true)
        return pickerView
    }()
    
    /// 时间选择器
    lazy var rightTimePickerView: UIPickerView = {
        let pickerView = UIPickerView(frame: CGRect(x: UIScreen.main.bounds.width / 2.0, y: 44, width: UIScreen.main.bounds.width / 2.0, height: 200))
        pickerView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.autoresizingMask = .flexibleWidth
        let index = timeDataArray.firstIndex(of: endTime) ?? 0
        pickerView.selectRow(index, inComponent: 0, animated: true)
        return pickerView
    }()
    /// 至
    lazy var middeleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: UIScreen.main.bounds.width / 2.0 - 20, y: 44 + 200 / 2.0 - 20, width: 40, height: 40))
        label.text = "~"
        label.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        label.textAlignment = .center
        return label
    }()
    /// 视图的父视图
    lazy var bgView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 200 - 44, width:  UIScreen.main.bounds.width, height: 200 + 44))
        view.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
        return view
    }()
    /// 取消
    lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 88, height: 44))
        button.setTitle("PT Button cancel".localized(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addActionHandlers { sender in
            self.dismissView()
        }
        return button
    }()
    /// 确定
    lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 88, y: 0, width: 88, height: 44))
        button.setTitle("PT Button comfirm".localized(), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addActionHandlers { sender in
            self.sureButtonClick()
        }
        return button
    }()
    /// 顶部的横线
    lazy var topLineView: UIView = {
        let line = UIView(frame: CGRect(x: 0, y: 44 - (1.0 / UIScreen.main.scale), width: UIScreen.main.bounds.width, height: (1.0 / UIScreen.main.scale)))
        line.backgroundColor = .gray
        return line
    }()

    init(startTime: String, endTime: String, complete: @escaping (String, String)->Void) {
        self.startTime = startTime
        self.endTime = endTime
        sureClosure = complete
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        initUI()
        commonUI()
        updateTheme()
    }
    
    /// 创建控件
    private func initUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.48)
        // 添加一个点击收回手势
        let tap = UITapGestureRecognizer { sender in
            self.dismissView()
        }
        addGestureRecognizer(tap)
        addSubview(bgView)
        bgView.addSubviews([cancelButton,sureButton,leftTimePickerView,rightTimePickerView,middeleLabel,topLineView])
        bgView.viewCornerRectCorner(cornerRadii: 10,corner: [.topLeft,.topRight])
        
        PTAnimationFunction.animationIn(animationView: bgView, animationType: .Bottom, transformValue: 244)
    }
    
    /// 添加控件和设置约束
    private func commonUI() {
        
    }
    
    /// 更新控件的颜色，字体，背景色等等
    private func updateTheme() {
        
    }
    
    //MARK: 弹出时间
    func showTime() {
        AppWindows!.addSubview(self)
    }
    
    //MARK: 界面消失
    @objc private func dismissView() {
        PTAnimationFunction.animationOut(animationView: bgView, animationType: .Bottom,toValue: bgView.layer.position.y) {
            
        } completion: { finish in
            self.removeFromSuperview()
        }
    }
    
    // MARK: 确定
    @objc func sureButtonClick() {
        sureClosure(startTime, endTime)
        dismissView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // 自定义分隔线属性
        
        // 自定义行属性
        var label = view as? UILabel
        if label == nil {
            label = UILabel()
            label!.font = .appfont(size: 18)
        }
        label!.textColor = PTAppBaseConfig.share.viewDefaultTextColor
        label!.textAlignment = .center
        label!.text = timeDataArray[row]
        
        return label!
    }
    
    // MARK: 将在滑动停止后触发，并打印出选中列和行索引
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == leftTimePickerView {
            startTime = timeDataArray[row]
//             PTNSLogConsole("左边时间：\(timeDataArray[row])， row = \(row) component = \(component)")
        } else {
            endTime = timeDataArray[row]
//             PTNSLogConsole("右边时间：\(timeDataArray[row])， row = \(row) component = \(component)")
        }
    }
}
