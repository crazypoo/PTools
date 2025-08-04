//
//  PTAutoScrollLabel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/6/29.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import AttributedString

public enum PTScrollDirection {
    case up,down
}

public class PTAutoScrollLabel: UIView {
    private let scrollView = UIScrollView()
    private var labels: [UILabel] = []
    private var timer: Timer?
    private var currentIndex = 0
    private var messages: [String] = []

    public var scrollInterval: TimeInterval = 2.0
    public var textFont: UIFont = .systemFont(ofSize: 14)
    public var textColor: UIColor = .label
    public var numberOfLines: Int = 1
    public var lineSpacing: CGFloat = 4
    public var scrollDirection: PTScrollDirection = .up
    public var textAlignment:NSTextAlignment = .right
    public var onTap: ((Int, String) -> Void)?

    public override init(frame: CGRect) {
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
        scrollView.clipsToBounds = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    public func configure(with texts: [String]) {
        stopScrolling()
        messages = texts
        currentIndex = scrollDirection == .up ? 0 : max(0, texts.count - 1)

        // 清空旧内容
        labels.forEach { $0.removeFromSuperview() }
        labels.removeAll()

        for (i, text) in texts.enumerated() {
            let label = UILabel()
            label.numberOfLines = numberOfLines

            if text.containsHTMLTags(),let data = text.data(using: .utf8) {
                let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ]
                if let attributedString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil) {
                    let fullRange = NSRange(location: 0, length: attributedString.length)
                    attributedString.addAttribute(.font, value: textFont, range: fullRange)
                    attributedString.addAttribute(.foregroundColor, value: textColor, range: fullRange)
                    label.attributedText = attributedString
                } else {
                    label.text = text
                    label.font = textFont
                    label.textColor = textColor
                    label.textAlignment = textAlignment
                }
            } else {
                let nameAtt:ASAttributedString = """
                            \(wrap: .embedding("""
                            \(text,.foreground(textColor),.font(textFont))
                            """),.paragraph(.alignment(textAlignment),.lineSpacing(lineSpacing)))
                            """
                label.attributed.text = nameAtt
            }
            
            label.tag = i
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer { sender in
                if let ges = sender as? UITapGestureRecognizer {
                    self.handleTap(ges)
                }
            }
            label.addGestureRecognizer(tap)

            scrollView.addSubview(label)
            labels.append(label)

            // 使用 SnapKit 设置 label 位置
            label.snp.makeConstraints { make in
                make.width.equalTo(self.frame.size.width)
                make.height.equalTo(self.frame.size.height)
                make.top.equalToSuperview().offset(CGFloat(i) * bounds.height)
                make.left.equalTo(0)
            }
        }

        scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height * CGFloat(texts.count))
        scrollView.contentOffset = scrollDirection == .up ? .zero : CGPoint(x: 0, y: scrollView.contentSize.height - bounds.height)

        startScrolling()
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        let index = label.tag
        if index < messages.count {
            onTap?(index, messages[index])
        }
    }

    private func startScrolling() {
        guard messages.count > 1 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] _ in
            self?.scrollToNext()
        }
    }

    public func stopScrolling() {
        timer?.invalidate()
        timer = nil
    }

    private func scrollToNext() {
        guard !messages.isEmpty else { return }

        if scrollDirection == .up {
            currentIndex = (currentIndex + 1) % messages.count
        } else {
            currentIndex = (currentIndex - 1 + messages.count) % messages.count
        }

        let offsetY = CGFloat(currentIndex) * bounds.height
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset.y = offsetY
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 重设 contentSize 和偏移（因为用到了 bounds）
        scrollView.contentSize = CGSize(width: bounds.width, height: bounds.height * CGFloat(labels.count))
        for (i, label) in labels.enumerated() {
            label.snp.updateConstraints { make in
                make.width.equalTo(self.frame.size.width)
                make.height.equalTo(self.frame.size.height)
                make.top.equalToSuperview().offset(CGFloat(i) * bounds.height)
            }
        }
        scrollView.contentOffset.y = CGFloat(currentIndex) * bounds.height
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
