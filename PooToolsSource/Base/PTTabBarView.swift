//
//  PTTabBarView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 20/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Lottie

public protocol PTTabBarItemContent {
    var view: UIView { get }
    func setSelected(_ selected: Bool, animated: Bool)
}

public struct PTTabBarItemConfig {
    let title: String
    let content: PTTabBarItemContent
    let viewController: UIViewController
}

final public class PTTabBarImageContent: PTTabBarItemContent {

    private let imageView = UIImageView()

    private let normalImage: UIImage
    private let selectedImage: UIImage?

    public init(normal: UIImage, selected: UIImage? = nil) {
        self.normalImage = normal
        self.selectedImage = selected
        imageView.contentMode = .scaleAspectFit
        imageView.image = normal
    }

    public var view: UIView { imageView }

    public func setSelected(_ selected: Bool, animated: Bool) {
        imageView.image = selected ? (selectedImage ?? normalImage) : normalImage
    }
}

final public class PTTabBarLottieContent: PTTabBarItemContent {

    private let lottieView = LottieAnimationView()
    private let normalName: String
    private let selectedName: String?

    public init(normal: String, selected: String? = nil) {
        self.normalName = normal
        self.selectedName = selected
        lottieView.loopMode = .playOnce
        lottieView.animation = .named(normal)
    }

    public var view: UIView { lottieView }

    public func setSelected(_ selected: Bool, animated: Bool) {
        let name = selected ? (selectedName ?? normalName) : normalName
        lottieView.animation = .named(name)

        if animated && selected {
            lottieView.play()
        } else {
            lottieView.currentProgress = selected ? 1 : 0
        }
    }
}

final public class PTTabBarItemView: UIControl {

    private let titleLabel = UILabel()
    private var content: PTTabBarItemContent!

    public var isSelectedItem = false {
        didSet {
            content.setSelected(isSelectedItem, animated: true)
            titleLabel.textColor = isSelectedItem ? .systemBlue : .gray
        }
    }

    public init(content: PTTabBarItemContent, title: String) {
        super.init(frame: .zero)

        self.content = content
        setupUI(title: title)
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setupUI(title: String) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textAlignment = .center

        addSubview(content.view)
        addSubview(titleLabel)

        content.view.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(28)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(content.view.snp.bottom).offset(2)
            $0.left.right.bottom.equalToSuperview()
        }
    }
}

final public class PTTabBarView: UIView {

    public var didSelectIndex: ((Int) -> Void)?

    private var items: [PTTabBarItemView] = []

    public func setup(configs: [PTTabBarItemConfig]) {

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)

        stack.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(CGFloat.kTabbarHeight)
        }

        for (index, config) in configs.enumerated() {
            let item = PTTabBarItemView(content: config.content, title: config.title)

            item.addAction(UIAction { [weak self] _ in
                self?.select(index)
            }, for: .touchUpInside)

            items.append(item)
            stack.addArrangedSubview(item)
        }

        select(0)
    }

    public func select(_ index: Int) {
        for (i, item) in items.enumerated() {
            item.isSelectedItem = (i == index)
        }
        didSelectIndex?(index)
    }
}
