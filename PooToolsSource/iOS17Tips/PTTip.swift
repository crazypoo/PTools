//
//  PTTip.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import TipKit
import SnapKit

@available(iOS 17, *)
// MARK: - 自定义Tip
public struct TestTip: Tip {
    // 标题
    public var title: Text {
        Text(tipTitles)
    }

    // 消息
    public var message: Text? {
        Text(messageTitles)
    }

    // 图片
    public var asset: Image? {
        Image(systemName: "globe")
    }
    
    public var id: String {
        newId
    }
    
    public var newId: String
    public var tipTitles:String
    public var messageTitles:String

    // 按钮
    public var actions: [Action] {
        [
            Action(id: "id_more", title: "更多"),
            Action(id: "id_dismiss", title: "关闭")
        ]
    }
    
    // 显示规则
    // 1. 基于参数规则
    @Parameter
    public static var showTip: Bool = false
    // 2. 基于事件规则
    public static let appOpenedCount = Event(id: "appOpenedCount")
    public var rules: [Rule] {
        [
            //                // 在一周内事件次数 < 3
            //                $0.donations.donatedWithin(.week).count < 3
            //                // 在三天内事件次数 > 3
            //                $0.donations.donatedWithin(.days(3)).count > 3
            #Rule(Self.$showTip) { $0 == true }, // showTip为true
            #Rule(Self.appOpenedCount) { $0.donations.count >= 1 } // 打开超过3次
        ]
    }

    // 选项
    public var options: [TipOption] {
        [
            Tip.IgnoresDisplayFrequency(true), // 忽略显示频率限制即立即显示
//            Tip.MaxDisplayCount(10) // 最大显示次数
        ]
    }
}

@available(iOS 17, *)
// MARK: - 自定义Tip
public struct Test1Tip: Tip {
    public var title: Text {
        Text("操作提示")
            .foregroundStyle(.red)
            .font(.title2)
            .fontDesign(.serif)
            .bold()
    }

    public var message: Text? {
        Text("通过触摸屏幕显示TipKit")
            .foregroundStyle(.white)
            .font(.title3)
            .fontDesign(.monospaced)
    }

    public var asset: Image? {
        Image(systemName: "info.bubble")
    }
}

@available(iOS 17, *)
public class PTTip: NSObject {
    public static let shared = PTTip()
    // TipUIPopoverViewController
    private var tipUIPopoverViewController: TipUIPopoverViewController?
    
    /**
     这里只是一个常规使用在AppDelegate上的方法,如果自定义就自己在AppDelegate上编辑
     */
    public func appdelegateTipSet() {
        try? Tips.configure([
            // 显示频率
            .displayFrequency(.immediate),
            // 数据存储位置
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    public func showTip(tips: any Tip,
                 sender:UIView,
                 content:PTBaseViewController,
                 customHandler:PTActionTask? = nil,
                 actionHandler:((Tip.Action)->Void)? = nil,
                        tipDismissHandler:PTActionTask? = nil) {
        if customHandler != nil {
            customHandler!()
        }
        // 显隐TipUIPopoverViewController
        Task { @MainActor in
            for await shouldDisplay in tips.shouldDisplayUpdates {
                if shouldDisplay {
                    tipUIPopoverViewController = TipUIPopoverViewController(tips, sourceItem: sender,actionHandler: { action in
                        if actionHandler != nil {
                            actionHandler!(action)
                        }
                    })
                    content.present(tipUIPopoverViewController!, animated: true)
                } else {
                    tipUIPopoverViewController?.dismiss(animated: true, completion: tipDismissHandler)
                }
            }
        }
    }
    
    public func showTipsInView(tips: any Tip,
                        arrowEdge: Edge? = nil,
                        tipUISet:((TipUIView)->Void)? = nil,
                        content:PTBaseViewController,
                        closure: @escaping (_ make: ConstraintMaker) -> Void,
                        customHandler:PTActionTask? = nil,
                        actionHandler:((Tip.Action)->Void)? = nil,
                               tipDismissHandler:PTActionTask? = nil) {
        let tipUIView = TipUIView(tips, arrowEdge: arrowEdge) { actions in
            if actionHandler != nil {
                actionHandler!(actions)
            }
        }
        if tipUISet != nil {
            tipUISet!(tipUIView)
        } else {
            tipUIView.backgroundColor = .black
            tipUIView.tintColor = .red
            tipUIView.cornerRadius = 6.0
            tipUIView.imageSize = CGSize(width: 40, height: 40)
            tipUIView.translatesAutoresizingMaskIntoConstraints = false
        }

        if customHandler != nil {
            customHandler!()
        }
        
        Task { @MainActor in
            for await shouldDisplay in tips.shouldDisplayUpdates {
                if shouldDisplay {
                    content.view.addSubview(tipUIView)
                    tipUIView.snp.makeConstraints(closure)
                } else {
                    tipUIView.removeFromSuperview()
                    if tipDismissHandler != nil {
                        tipDismissHandler!()
                    }
                }
            }
        }
    }
}
