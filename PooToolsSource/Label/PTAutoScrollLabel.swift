//
//  PTAutoScrollLabel.swift
//  BABBox
//
//  Created by 邓杰豪 on 2025/10/8.
//  Copyright © 2025 BAB. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString
import SwifterSwift

public enum PTScrollDirection {
    case up
    case down
    case left
    case right
}

public class PTAutoScrollLabel: UIView {

    private let scrollView = UIScrollView()
    private var labels: [UILabel] = []
    private var timer: Timer?
    private var messages: [String] = []
    private var bgColors: [UIColor] = []

    private var marqueeOffset: CGFloat = 0
    private var lastBounds: CGRect = .zero // 用于记录上一次的尺寸，避免重复布局

    // MARK: - Configurable Properties
    public var scrollInterval: TimeInterval = 2.0
    public var textFont: UIFont = .systemFont(ofSize: 14)
    public var textColor: UIColor = .label
    public var numberOfLines: Int = 1
    public var lineSpacing: CGFloat = 4
    public var textAlignment: NSTextAlignment = .left
    public var scrollDirection: PTScrollDirection = .up
    public var itemSpacing: CGFloat = 20
    public var marqueeSpeed: CGFloat = 40

    public var onTap: ((Int, String) -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        scrollView.isScrollEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = true
        // 关键点：禁用系统默认的 ContentInset 调整机制
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Configure
    public func configure(with texts: [String], backgroundColors: [UIColor]? = nil) {
        stopScrolling()
        messages = texts
        bgColors = backgroundColors ?? Array(repeating: .clear, count: texts.count)
        
        // 强制触发 layoutSubviews 以便在有真实 bounds 后再构建 UI
        setNeedsLayout()
        layoutIfNeeded()
    }

    // 将重建 UI 的逻辑独立出来
    private func rebuildLabels() {
        stopScrolling()
        
        labels.forEach { $0.removeFromSuperview() }
        labels.removeAll()

        guard !messages.isEmpty else { return }

        if scrollDirection == .left || scrollDirection == .right {
            setupHorizontalMarqueeLabels()
        } else {
            setupVerticalLabels()
        }

        startScrolling()
    }

    // MARK: - Label Setup
    private func setupVerticalLabels() {
        // 同样复制一份数据实现无缝垂直滚动
        let displayMessages = messages + messages
        let displayColors = bgColors + bgColors

        for (i, text) in displayMessages.enumerated() {
            // 安全获取颜色
            let color = displayColors.indices.contains(i) ? displayColors[i] : .clear
            let label = createLabel(text: text, index: i, bgColor: color)
            scrollView.addSubview(label)
            labels.append(label)

            label.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalToSuperview()
                make.left.equalTo(0)
                make.top.equalToSuperview().offset(CGFloat(i) * bounds.height)
            }
        }
        scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height * CGFloat(labels.count))
        // 如果是向下滚动，初始位置设置在第二部分，留出向上回滚的空间
        scrollView.contentOffset = scrollDirection == .down ? CGPoint(x: 0, y: scrollView.contentSize.height / 2) : .zero
    }

    private func setupHorizontalMarqueeLabels() {
        var xOffset: CGFloat = 0
        let displayMessages = messages + messages
        let displayColors = bgColors + bgColors

        for (i, text) in displayMessages.enumerated() {
            let color = displayColors.indices.contains(i) ? displayColors[i] : .clear
            let label = createLabel(text: text, index: i, bgColor: color)
            scrollView.addSubview(label)
            labels.append(label)

            let size = text.size(withAttributes: [.font: textFont])
            label.frame = CGRect(x: xOffset, y: 0, width: size.width + 10, height: bounds.height)
            xOffset += label.frame.width + itemSpacing
            
            // 安全使用 SwifterSwift 拓展
            label.viewCorner(radius: bounds.height / 2)
        }

        scrollView.contentSize = CGSize(width: xOffset, height: bounds.height)
        scrollView.contentOffset = scrollDirection == .left ? .zero : CGPoint(x: scrollView.contentSize.width / 2, y: 0)
        marqueeOffset = scrollView.contentOffset.x
    }

    private func createLabel(text: String, index: Int, bgColor: UIColor) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.backgroundColor = bgColor
        label.font = textFont
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.text = text
        label.isUserInteractionEnabled = true
        // 绑定真实的原始数据索引
        label.tag = index % messages.count
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        return label
    }

    // MARK: - Tap
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        let index = label.tag
        guard index < messages.count else { return }
        onTap?(index, messages[index])
    }

    // MARK: - Scrolling Logic
    private func startScrolling() {
        guard messages.count > 0 else { return }
        stopScrolling()

        if scrollDirection == .left || scrollDirection == .right {
            // 使用弱引用代理解决 CADisplayLink 的循环引用问题
            let displayLink = CADisplayLink(target: WeakTargetProxy(target: self), selector: #selector(WeakTargetProxy.onUpdate))
            displayLink.add(to: .main, forMode: .common)
            self.displayLink = displayLink
        } else {
            // 垂直方向 Timer (iOS 10+ 推荐使用 block API 避免 Selector 循环引用)
            timer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] _ in
                self?.scrollVerticalNext()
            }
        }
    }

    public func stopScrolling() {
        timer?.invalidate()
        timer = nil
        displayLink?.invalidate()
        displayLink = nil
    }

    private func scrollVerticalNext() {
        guard labels.count > 1 else { return }
        var offset = scrollView.contentOffset
        let step = bounds.height
        let halfHeight = scrollView.contentSize.height / 2

        switch scrollDirection {
        case .up:
            offset.y += step
        case .down:
            offset.y -= step
        default:
            break
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset = offset
        }) { [weak self] _ in
            guard let self = self else { return }
            // 动画结束后，检查是否需要无缝重置偏移量
            let currentOffsetY = self.scrollView.contentOffset.y
            
            if self.scrollDirection == .up && currentOffsetY >= halfHeight {
                // 回到克隆体对应的开头
                self.scrollView.contentOffset.y = currentOffsetY - halfHeight
            } else if self.scrollDirection == .down && currentOffsetY <= 0 {
                // 回到克隆体对应的结尾
                self.scrollView.contentOffset.y = currentOffsetY + halfHeight
            }
        }
    }

    private weak var displayLink: CADisplayLink?

    // 设置为 public 以允许 Proxy 访问
    @objc public func updateMarquee() {
        guard scrollView.contentSize.width > bounds.width else { return }

        let frameInterval: CGFloat = 1.0 / 60.0
        let delta = marqueeSpeed * frameInterval

        if scrollDirection == .left {
            marqueeOffset += delta
            if marqueeOffset >= scrollView.contentSize.width / 2 {
                marqueeOffset -= scrollView.contentSize.width / 2
            }
        } else if scrollDirection == .right {
            marqueeOffset -= delta
            if marqueeOffset <= 0 {
                marqueeOffset += scrollView.contentSize.width / 2
            }
        }

        scrollView.contentOffset.x = marqueeOffset
    }

    // MARK: - Lifecycle
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 只有当尺寸发生真正改变，且尺寸合法时，才重新构建视图。防止无限嵌套与冗余计算！
        if bounds != lastBounds && bounds.width > 0 && bounds.height > 0 {
            lastBounds = bounds
            rebuildLabels()
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopScrolling()
        } else {
            // 如果已经被赋予了尺寸且有数据，恢复滚动
            if bounds.width > 0 && !messages.isEmpty {
                startScrolling()
            }
        }
    }

    deinit {
        stopScrolling()
    }
}

// MARK: - WeakTargetProxy (解决 CADisplayLink 内存泄漏)
fileprivate class WeakTargetProxy {
    weak var target: PTAutoScrollLabel?

    init(target: PTAutoScrollLabel) {
        self.target = target
    }

    @objc func onUpdate() {
        target?.updateMarquee()
    }
}
