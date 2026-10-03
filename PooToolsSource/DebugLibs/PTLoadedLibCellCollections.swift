//
//  PTLoadedLibCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/4/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

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
        super.init(coder: coder)
    }
    
    @MainActor
    func configure(with library: PTLoadedLibrary) {
        let displayName: String
        if library.name.hasSuffix(".app") || library.name.hasSuffix(".framework") || library.name.hasSuffix(".dylib") {
            displayName = library.name
        } else if let appPath = library.path.components(separatedBy: ".app/").first,
                  library.path.contains(".app/") {
            displayName = ((appPath + ".app") as NSString).lastPathComponent
        } else {
            displayName = library.name
        }

        let att: PTRichText = """
        \(wrap: .embedding("""
        \(displayName,.foreground(.lightGray),.font(.appfont(size: 18)),.paragraph(.alignment(.left),.lineSpacing(2.5)))
        \(library.summaryDescription,.foreground(.lightGray),.font(.appfont(size: 14)),.paragraph(.alignment(.left),.lineSpacing(2.5)))
        """))
        """
        libName.attributedText = att.value

        statusLabel.text = library.isPrivate ? "Private" : "Public"
        statusLabel.textColor = library.isPrivate ? .systemRed : .systemGreen
        statusLabel.backgroundColor = statusLabel.textColor.withAlphaComponent(0.5)
        statusLabel.snp.updateConstraints { make in
            make.width.equalTo(statusLabel.sizeFor().width + 16)
        }

        let isExpanded = library.isExpanded
        arrowImage.isHidden = library.isLoading
        arrowImage.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
        if library.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}
