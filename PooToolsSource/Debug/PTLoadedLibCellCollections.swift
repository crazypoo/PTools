//
//  PTLoadedLibCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/4/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import AttributedString

final class PTLibraryHeaderView: UIView {
    
    // MARK: - Properties
    
    var onToggle: PTActionTask?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var libName:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    lazy var arrowImage:UIImageView = {
        let view = UIImageView()
        view.image = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
        return view
    }()
    
    lazy var statusLabel:UILabel = {
        let view = UILabel()
        view.font = .appfont(size: 14)
        view.textAlignment = .center
        return view
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .white)
        }
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Setup
    
    private func setup() {
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        containerView.addSubviews([arrowImage,libName,statusLabel,loadingIndicator])
        arrowImage.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
        }
        
        libName.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(4.5)
            make.right.equalTo(self.arrowImage.snp.left).offset(-4.5)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.right.top.equalTo(self.libName)
            make.height.equalTo(20)
            make.width.equalTo(0)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.edges.equalTo(self.arrowImage)
        }
        
        let tapGesture = UITapGestureRecognizer { sender in
            self.onToggle?()
        }
        containerView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Configuration
    
    func configure(with library: PTLoadedLibrary) {
        PTGCDManager.gcdMain {
            // Extract a cleaner name from the path if needed
            let displayName: String
            if library.name.hasSuffix(".app") || library.name.hasSuffix(".framework") || library.name.hasSuffix(".dylib") {
                displayName = library.name
            } else if library.path.contains(".app/") {
                // For app executables, show the app name
                let components = library.path.components(separatedBy: ".app/")
                if components.count > 1 {
                    let appPath = components[0] + ".app"
                    displayName = (appPath as NSString).lastPathComponent
                } else {
                    displayName = library.name
                }
            } else {
                displayName = library.name
            }
            
            let desc = library.path + "\nSize: " + library.size + " Address: " + library.address
            let att:ASAttributedString = """
        \(wrap: .embedding("""
        \(displayName,.foreground(.lightGray),.font(.appfont(size: 18)),.paragraph(.alignment(.left),.lineSpacing(2.5)))
        \(desc,.foreground(.lightGray),.font(.appfont(size: 14)),.paragraph(.alignment(.left),.lineSpacing(2.5)))
        """))
        """
            self.libName.attributed.text = att
            
            self.statusLabel.text = library.isPrivate ? "Private" : "Public"
            self.statusLabel.textColor = library.isPrivate ? .systemRed : .systemGreen
            self.statusLabel.backgroundColor = self.statusLabel.textColor.withAlphaComponent(0.5)
            self.statusLabel.snp.updateConstraints { make in
                make.width.equalTo(self.statusLabel.sizeFor().width + 16)
            }

            // Configure expand indicator and loading state
            if library.isLoading {
                self.arrowImage.isHidden = true
                self.loadingIndicator.startAnimating()
            } else {
                self.arrowImage.isHidden = false
                self.loadingIndicator.stopAnimating()
            }
        }
    }
}
