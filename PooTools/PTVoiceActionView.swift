//
//  PTVoiceActionView.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 16/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import SnapKit

class PTVoiceActionView: PTBaseMaskView {

    let visualizerViewBaseBackgroundColor:UIColor = .black.withAlphaComponent(0.55)
    
    lazy var visualizerView:PTSoundVisualizerView = {
        let view = PTSoundVisualizerView()
        view.backgroundColor = self.visualizerViewBaseBackgroundColor
        view.lineColor = .red
        return view
    }()
    
    lazy var translateLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.font = .appfont(size: 17, bold: true)
        view.numberOfLines = 0
        view.lineBreakMode = .byTruncatingTail
        view.textColor = .white
        return view
    }()
    
    lazy var actionInfoLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = .white
        view.font = .appfont(size: 15)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews([visualizerView, translateLabel, actionInfoLabel])
        visualizerView.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(88)
            make.centerX.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
        }
        visualizerView.viewCorner(radius: 5)
        
        translateLabel.isHidden = true
        translateLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(self.visualizerView.snp.top).offset(-5)
            make.height.equalTo(0)
        }
        
        actionInfoLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.visualizerView)
            make.top.equalTo(self.visualizerView.snp.bottom).offset(5)
        }
        actionInfoLabel.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}
