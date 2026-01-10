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

class PTloadedLibHeader : PTBaseCollectionReusableView {
    static let ID = "PTloadedLibHeader"
    
    var onToggle: PTActionTask?

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
        indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([arrowImage,libName,statusLabel,loadingIndicator])
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
        addGestureRecognizer(tapGesture)
    }
    
    @MainActor required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
