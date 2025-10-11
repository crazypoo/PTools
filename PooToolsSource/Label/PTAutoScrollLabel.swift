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

    // 当前偏移量（仅跑马灯模式）
    private var marqueeOffset: CGFloat = 0

    // MARK: - Configurable Properties
    public var scrollInterval: TimeInterval = 2.0
    public var textFont: UIFont = .systemFont(ofSize: 14)
    public var textColor: UIColor = .label
    public var numberOfLines: Int = 1
    public var lineSpacing: CGFloat = 4
    public var textAlignment: NSTextAlignment = .left
    public var scrollDirection: PTScrollDirection = .up
    public var itemSpacing: CGFloat = 20 // 左右方向间隔距离
    public var marqueeSpeed: CGFloat = 40 // 跑马灯速度（点/秒）

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
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Configure
    public func configure(with texts: [String], backgroundColors: [UIColor]? = nil) {
        stopScrolling()
        messages = texts
        bgColors = backgroundColors ?? Array(repeating: .clear, count: texts.count)

        labels.forEach { $0.removeFromSuperview() }
        labels.removeAll()

        guard !texts.isEmpty else { return }

        if scrollDirection == .left || scrollDirection == .right {
            setupHorizontalMarqueeLabels()
        } else {
            setupVerticalLabels()
        }

        startScrolling()
    }

    // MARK: - Label Setup
    private func setupVerticalLabels() {
        for (i, text) in messages.enumerated() {
            let label = createLabel(text: text, index: i)
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
    }

    private func setupHorizontalMarqueeLabels() {
        var xOffset: CGFloat = 0
        for (i, text) in messages.enumerated() {
            let label = createLabel(text: text, index: i)
            scrollView.addSubview(label)
            labels.append(label)

            let size = text.size(withAttributes: [.font: textFont])
            label.frame = CGRect(x: xOffset, y: 0, width: size.width + 10, height: bounds.height)
            xOffset += label.frame.width + itemSpacing
            
            label.viewCorner(radius: self.bounds.height / 2)
        }

        // 为了实现无缝滚动，复制一份内容拼接在后面
        for (i, text) in messages.enumerated() {
            let label = createLabel(text: text, index: i + messages.count)
            label.backgroundColor = bgColors[i % bgColors.count]
            scrollView.addSubview(label)
            labels.append(label)

            let size = text.size(withAttributes: [.font: textFont])
            label.frame = CGRect(x: xOffset, y: 0, width: size.width + 10, height: bounds.height)
            xOffset += label.frame.width + itemSpacing
            
            label.viewCorner(radius: self.bounds.height / 2)
        }

        scrollView.contentSize = CGSize(width: xOffset, height: bounds.height)
        scrollView.contentOffset = scrollDirection == .left ? .zero : CGPoint(x: scrollView.contentSize.width / 2, y: 0)
    }

    private func createLabel(text: String, index: Int) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.backgroundColor = bgColors[safe: index % bgColors.count] ?? .clear
        label.font = textFont
        label.textColor = textColor
        label.textAlignment = textAlignment
        label.text = text
        label.isUserInteractionEnabled = true
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
            // 跑马灯效果用 displayLink 更平滑
            let displayLink = CADisplayLink(target: self, selector: #selector(updateMarquee))
            displayLink.add(to: .main, forMode: .common)
            self.displayLink = displayLink
        } else {
            // 垂直方向用 timer
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

        switch scrollDirection {
        case .up:
            offset.y += step
            if offset.y >= scrollView.contentSize.height - step {
                offset.y = 0
            }
        case .down:
            offset.y -= step
            if offset.y < 0 {
                offset.y = scrollView.contentSize.height - step
            }
        default:
            break
        }

        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = offset
        }
    }

    private weak var displayLink: CADisplayLink?

    @objc private func updateMarquee() {
        guard scrollView.contentSize.width > bounds.width else { return }

        let frameInterval: CGFloat = 1.0 / 60.0 // 每帧
        let delta = marqueeSpeed * frameInterval

        if scrollDirection == .left {
            marqueeOffset += delta
            if marqueeOffset >= scrollView.contentSize.width / 2 {
                marqueeOffset = 0
            }
        } else if scrollDirection == .right {
            marqueeOffset -= delta
            if marqueeOffset <= 0 {
                marqueeOffset = scrollView.contentSize.width / 2
            }
        }

        scrollView.contentOffset.x = marqueeOffset
    }

    // MARK: - Lifecycle
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 当方向变化时重置布局
        if scrollDirection == .left || scrollDirection == .right {
            setupHorizontalMarqueeLabels()
        } else {
            setupVerticalLabels()
        }
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopScrolling()
        } else {
            startScrolling()
        }
    }

    deinit {
        stopScrolling()
    }
}
