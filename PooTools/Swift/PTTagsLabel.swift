//
//  PTTagsLabel.swift
//  Diou
//
//  Created by ken lam on 2021/10/11.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

let BTN_Tags_Tag = 784843
enum PTTagsLabelShowStatus {
    case Normal
    case Image
}

enum PTTagsLabelShowSubStatus {
    case Normal
    case AllSameWidth
    case NoTitle
}

enum PTTagPosition {
    case Left
    case Center
    case Right
}

class PTTagsConfig:PTBaseModel
{
    /*! @brief item之间的左右间距
     */
    var itemHerMargin : CGFloat? = 0
    /*! @brief item之间的上下间距
     */
    var itemVerMargin : CGFloat? = 0
    /*! @brief item的高度
     */
    var itemHeight : CGFloat? = 0
    /*! @brief item的长度 (只在图片模式使用)
     */
    var itemWidth : CGFloat? = 0
    /*! @brief item标题距左右边缘的距离 (默认10)
     */
    var itemContentEdgs : CGFloat? = 10
    /*! @brief 最顶部的item层到本view最顶部的距离,最底部的item层到本view最底部的距离 (0.1基本可看作无距离)
     */
    var topBottomSpace : CGFloat? = 0.1
    /*! @brief item字体 (默认系统12)
     */
    var tagsFont : UIFont? = .systemFont(ofSize: 12)
    /*! @brief 没选中字体颜色 (默认[UIColor grayColor])
     */
    var normalTitleColor : UIColor? = .gray
    /*! @brief 选中字体颜色 (默认[UIColor greenColor])
     */
    var selectedTitleColor : UIColor? = .green
    /*! @brief 默认背景颜色 (默认[UIColor clearColor])
     */
    var backgroundColor : UIColor? = .clear
    /*! @brief 选中背景颜色 (默认[UIColor clearColor])
     */
    var backgroundSelectedColor : UIColor? = .clear
    /*! @brief 没选中背景图片 (只在纯文字模式下使用)
     */
    var normalBgImage : String? = ""
    /*! @brief 选中背景图片 (只在纯文字模式下使用)
     */
    var selectedBgImage : String? = ""
    /*! @brief 展示样式 (图片模式下使用)
     */
    var showStatus : PTTagsLabelShowStatus? = .Normal
    /*! @brief 图片与文字之间展示排版样式 (图片模式下使用)
     */
    var insetsStyle : BKLayoutButtonStyle? = .leftImageRightTitle
    /*! @brief 图片与文字之间展间隙 (图片模式下使用)
     */
    var imageAndTitleSpace :CGFloat?
    /*! @brief 是否有边框  (默认没有边框)
     */
    var hasBorder : Bool? = false
    /*! @brief 边框宽度 (默认0.5)
     */
    var borderWidth : CGFloat? = 0.5
    /*! @brief 边框颜色 (默认[UIColor redColor])
     */
    var borderColor : UIColor? = .red
    /*! @brief 边框颜色已选 (默认[UIColor redColor])
     */
    var borderColorSelected : UIColor? = .red
    /*! @brief 边框弧度 (默认item高度/2)
     */
    var cornerRadius : CGFloat? = 0

    /*! @brief 是否可以选中 (默认为NO (YES时为单选))
     */
    var isCanSelected : Bool? = false
    /*! @brief 是否可以取消选中
     */
    var isCanCancelSelected : Bool? = false
    /*! @brief 是否可以多选
     */
    var isMulti : Bool? = false
    /*! @brief 单个选中对应的标题 (初始化时默认选中的)
     */
    var singleSelectedTitle : String? = ""
    /*! @brief 多个选中对应的标题数组(初始化时默认选中的)
     */
    var selectedDefaultTags : [String]?
    /*! @brief Tag的展示位置默认左边
    */
    var tagPosition : PTTagPosition? = .Left
    /*! @brief Tag普通图片
    */
    var normalImage : [String]?
    /*! @brief Tag已选图片
    */
    var selectedImage : [String]?
    /*! @brief Tag标题
    */
    var titleNormal : [String]?
    /*! @brief TagImageSize
    */
    var tagImageSize : CGSize?
    /*! @brief Tag子展示属性
    */
    var showSubStatus : PTTagsLabelShowSubStatus? = .Normal
    /*! @brief Tag锁定按钮宽度
    */
    var lockWidth : Bool? = false
    /*! @brief Tag字符对齐情况
    */
    var textAlignment : NSTextAlignment? = .center
    /*! @brief 最后一行是否居中(仅限tagPosition时使用)
    */
    var LastRowCenter:Bool? = false
}

class PTTagsLabel: UIView {
    
    var tagHeightBlock:((_ tags:PTTagsLabel,_ viewHeight:CGFloat)->Void)?
    var tagViewHadSectionAndSetcionLastTagAndTagInSectionCount:((_ tags:PTTagsLabel,_ section:Int,_ lastRowTagArr:[Int],_ sectionCountArr:[Int])->Void)?
    var tagBtnClickedBlock:((_ tags:PTTagsLabel,_ currentTag:BKLayoutButton,_ index:Int)->Void)?
    
    private var section:Int = 0
    private var rowLastTagArr = [Int]()
    private var sectionCountArr = [Int]()
    private var showImage:Bool? = false
    private var tagsTitleArr = [String]()
    private var selectedTagsArr = [String]()
    private var normalTagsArr = [String]()
    private var multiSelectedTags = [String]()
    private var selectedBtn : BKLayoutButton?
    private var bgImageView : UIImageView = {
        let image = UIImageView()
        image.isUserInteractionEnabled = true
        return image
    }()
    
    
    var tagConfig : PTTagsConfig?
//    {
//        didSet
//        {
//        }
//    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createTag()
    {
        subviews.enumerated().forEach { (index,value) in
            value.removeFromSuperview()
        }

        switch tagConfig?.showStatus {
        case .Normal:
            showImage = false
            tagsTitleArr = tagConfig!.titleNormal!
        case .Image:
            showImage = true
            tagsTitleArr = tagConfig!.titleNormal!
            normalTagsArr = tagConfig!.normalImage!
            selectedTagsArr = tagConfig!.selectedImage!
        default:break
        }
        
        if (tagConfig!.selectedDefaultTags?.count ?? 0) > 0
        {
            multiSelectedTags = tagConfig!.selectedDefaultTags!
        }
        
        addSubview(bgImageView)
        
        var lastBtnRect = CGRect.zero
        var hMargin : CGFloat = 0.0
        var orgin_Y : CGFloat = 0.0
        let itemContentMargin : CGFloat = tagConfig!.itemContentEdgs!
        let topBottomSpace : CGFloat = tagConfig!.topBottomSpace!
        let font : UIFont = tagConfig!.tagsFont!
        
        var row:Int = 0
        
//        var tagCountMax : Int = tagsTitleArr.count - 1
        
        var floatArr = NSMutableArray()
        tagsTitleArr.enumerated().forEach { (index,value) in
            if tagConfig!.lockWidth!
            {
                floatArr.add(PTUtils.sizeFor(string: value, font: font, height: CGFloat(MAXFLOAT), width: tagConfig!.itemWidth!).height)
            }
        }
        
        var maxValue:CGFloat = 0
        if floatArr.count > 0
        {
            maxValue = floatArr.value(forKeyPath: "@max.floatValue") as! CGFloat
        }
        
        tagsTitleArr.enumerated().forEach { (index,value) in
            let normalImage = normalTagsArr.count > 0 ? UIImage.init(named: normalTagsArr[index]) : UIImage()
            let title = value
            var titleWidth : CGFloat = 0
            var titleHeight : CGFloat = 0
            
            switch tagConfig!.showStatus {
            case .Normal:
                if tagConfig!.lockWidth!
                {
                    titleWidth = tagConfig!.itemWidth!
                    if maxValue > tagConfig!.itemHeight!
                    {
                        titleHeight = maxValue
                    }
                    else
                    {
                        titleHeight = tagConfig!.itemHeight!
                    }
                }
            case .Image:
                switch tagConfig!.showSubStatus {
                case .Normal:
                    if tagConfig!.insetsStyle == .leftImageRightTitle || tagConfig?.insetsStyle == .leftTitleRightImage
                    {
                        if tagConfig!.lockWidth!
                        {
                            let leftWidth = tagConfig!.itemWidth! - 2 * itemContentMargin + tagConfig!.tagImageSize!.width
                            let leftHieght = PTUtils.sizeFor(string: title, font: font, height: CGFloat(MAXFLOAT), width: leftWidth).height
                            titleWidth = tagConfig!.itemWidth!
                            if leftHieght > tagConfig!.itemHeight!
                            {
                                titleHeight = leftHieght
                            }
                            else
                            {
                                titleHeight = tagConfig!.itemHeight!
                            }
                        }
                        else
                        {
                            
                            titleWidth = PTUtils.sizeFor(string: title, font: font, height: tagConfig!.itemHeight!, width: CGFloat(MAXFLOAT)).width + 2 * itemContentMargin
                            titleHeight = tagConfig!.itemHeight!
                        }
                    }
                    else
                    {
                        let titleSize = title.size(withAttributes: [NSAttributedString.Key.font:font])
                        if tagConfig!.lockWidth!
                        {
                            titleWidth = tagConfig!.itemWidth!
                            titleHeight = tagConfig!.tagImageSize!.height + maxValue + 2 * 10
                        }
                        else
                        {
                            if titleSize.width > tagConfig!.tagImageSize!.width
                            {
                                titleWidth = titleSize.width + 2 * itemContentMargin
                            }
                            else
                            {
                                titleWidth = tagConfig!.tagImageSize!.width + 2 * itemContentMargin
                            }
                            titleHeight = tagConfig!.itemHeight!
                        }
                    }
                case .AllSameWidth:
                    titleWidth = tagConfig!.itemWidth!
                    titleHeight = maxValue
                case .NoTitle:
                    titleWidth = tagConfig!.tagImageSize!.width + 2 * itemContentMargin
                    titleHeight = tagConfig!.itemHeight!
                default:
                    break
                }
            default:
                break
            }
            
            if (lastBtnRect.maxX + tagConfig!.itemHerMargin! + titleWidth + 2 * itemContentMargin) > self.frame.width
            {
                lastBtnRect.origin.x = 0
                hMargin = 0
                lastBtnRect.size.width = 0
                orgin_Y += titleHeight + tagConfig!.itemVerMargin!
                
                let currentRowLastTag = row - BTN_Tags_Tag
                rowLastTagArr.append(currentRowLastTag)
                
                section += 1
            }
                
            if index == (tagsTitleArr.count - 1)
            {
                if !rowLastTagArr.contains(index)
                {
                    self.rowLastTagArr.append(index)
                }
            }
            
            let btn = BKLayoutButton.init(frame: CGRect.init(x: hMargin + lastBtnRect.maxX, y: topBottomSpace + orgin_Y, width: titleWidth, height: titleHeight))
            lastBtnRect = btn.frame
            hMargin = tagConfig!.itemHerMargin!
            btn.tag = BTN_Tags_Tag + index
            row = BTN_Tags_Tag + index
            btn.titleLabel?.numberOfLines = 0
            self.addSubview(btn)
            

            switch tagConfig!.showStatus {
            case .Normal:
                btn.setTitle(title, for: .normal)
                btn.setTitleColor(tagConfig!.normalTitleColor!, for: .normal)
                btn.setTitleColor(tagConfig!.selectedTitleColor!, for: .selected)
                btn.titleLabel?.textAlignment = tagConfig!.textAlignment!
                if !(tagConfig!.normalBgImage!).stringIsEmpty() && !(tagConfig!.selectedBgImage!).stringIsEmpty()
                {
//                    btn.setBackgroundImage(UIImage(named: tagConfig!.normalBgImage!), for: .normal)
                    btn.setBackgroundImage(UIImage(named: tagConfig!.selectedBgImage!), for: .normal)
                }
                btn.setMidSpacing(0)
            case .Image:
                switch tagConfig!.showSubStatus {
                case .NoTitle:
                    btn.setTitleColor(.clear, for: .normal)
                    btn.setTitle(title, for: .normal)
                    btn.setBackgroundImage(normalImage, for: .normal)
                    btn.setBackgroundImage(UIImage(named: selectedTagsArr[index]), for: .selected)
                default:
                    if tagConfig!.insetsStyle == .upImageDownTitle || tagConfig!.insetsStyle == .upTitleDownImage
                    {
                        btn.titleLabel?.textAlignment = tagConfig!.textAlignment!
                    }
                    
                    btn.setTitleColor(tagConfig!.normalTitleColor!, for: .normal)
                    btn.setTitleColor(tagConfig!.selectedTitleColor!, for: .normal)
                    btn.setTitle(title, for: .normal)
                    btn.setTitle(title, for: .selected)
                    btn.setImage(normalImage, for: .normal)
                    btn.setImage(UIImage(named: selectedTagsArr[index]), for: .normal)
                    btn.setMidSpacing(tagConfig!.imageAndTitleSpace!)
                }
            default:
                break
            }
            btn.backgroundColor = tagConfig?.backgroundColor
            btn.titleLabel?.font = font
            btn.addActionHandler { sender in
                if self.tagConfig!.isCanSelected!
                {
                    if self.tagConfig!.isMulti!
                    {
                        if self.tagConfig!.isCanCancelSelected!
                        {
                            sender.isSelected = !sender.isSelected
                            if sender.isSelected
                            {
                                if !self.multiSelectedTags.contains(sender.currentTitle!)
                                {
                                    self.multiSelectedTags.append(sender.currentTitle!)
                                }
                            }
                            else
                            {
                                if self.multiSelectedTags.contains(sender.currentTitle!)
                                {
                                    self.multiSelectedTags.removeAll(where: { $0 == sender.currentTitle} )
                                }
                            }
                        }
                        else
                        {
                            sender.isSelected = true
                            if !self.multiSelectedTags.contains(sender.currentTitle!)
                            {
                                self.multiSelectedTags.append(sender.currentTitle!)
                            }
                        }
                    }
                    else
                    {
                        if self.tagConfig!.isCanCancelSelected!
                        {
                            if self.selectedBtn == sender
                            {
                                sender.isSelected = !sender.isSelected
                                if sender.isSelected
                                {
                                    self.selectedBtn = sender as! BKLayoutButton
                                }
                                else
                                {
                                    self.selectedBtn = nil
                                }
                            }
                            else
                            {
                                self.selectedBtn?.isSelected = false
                                sender.isSelected = false
                                self.selectedBtn = sender as! BKLayoutButton
                            }
                        }
                        else
                        {
                            self.selectedBtn?.isSelected = false
                            self.btnBackgroundColorAndBorderColor(sender: self.selectedBtn!)
                            sender.isSelected = true
                            self.selectedBtn = sender as! BKLayoutButton
                        }
                    }
                }
                
                self.btnBackgroundColorAndBorderColor(sender: sender)
                let index = sender.tag - BTN_Tags_Tag
                if self.tagBtnClickedBlock != nil
                {
                    self.tagBtnClickedBlock!(self,sender as! BKLayoutButton,index)
                }
            }
            
            var frame = self.frame
            frame.size.height = btn.frame.maxY + topBottomSpace
            self.frame = frame
            bgImageView.frame = self.bounds
            
            if tagConfig!.hasBorder!
            {
                btn.viewCorner(radius: ((tagConfig!.cornerRadius! > 0) ? tagConfig!.cornerRadius! : (tagConfig!.itemHeight! / 2)),borderWidth: tagConfig!.borderWidth!,borderColor: tagConfig!.borderColor!)
            }
            
            if tagConfig!.isCanSelected!
            {
                if tagConfig!.isMulti!
                {
                    multiSelectedTags.enumerated().forEach { (index,value) in
                        if title == value
                        {
                            btn.isSelected = true
                        }
                    }
                }
                else
                {
                    if title == tagConfig!.singleSelectedTitle!
                    {
                        btn.isSelected = true
                        selectedBtn = btn
                    }
                }
            }
            else
            {
                btn.isSelected = false
            }
            self.btnBackgroundColorAndBorderColor(sender: btn)
        }
        
        if tagHeightBlock != nil
        {
            tagHeightBlock!(self,self.frame.height)
        }
        
        rowLastTagArr.append(normalTagsArr.count - 1)
        
        rowLastTagArr.enumerated().forEach { (index,vlaue) in
            if index == 0
            {
                let currentRowCount = (self.rowLastTagArr[index] + 1)
                self.sectionCountArr.append(currentRowCount)
            }
            else
            {
                let currentRowCount = self.rowLastTagArr[index] - self.rowLastTagArr[index - 1]
                self.sectionCountArr.append(currentRowCount)
            }
        }
        
        if tagViewHadSectionAndSetcionLastTagAndTagInSectionCount != nil
        {
            tagViewHadSectionAndSetcionLastTagAndTagInSectionCount!(self,section,rowLastTagArr,sectionCountArr)
        }

        self.createTagPosition(position: tagConfig!.tagPosition!)
    }
    
    func btnBackgroundColorAndBorderColor(sender:UIButton)
    {
        if tagConfig!.hasBorder!
        {
            if sender.isSelected
            {
                sender.layer.borderColor = tagConfig!.borderColorSelected!.cgColor
            }
            else
            {
                sender.layer.borderColor = tagConfig!.borderColor!.cgColor
            }
        }
        
        if sender.isSelected
        {
            sender.backgroundColor = tagConfig!.backgroundSelectedColor!
        }
        else
        {
            sender.backgroundColor = tagConfig!.backgroundColor!
        }
    }
        
    private func createTagPosition(position:PTTagPosition)
    {
        for j in 0...(section)
        {
            var totalW:CGFloat = 0
            var currentSectionTotalW:CGFloat = 0
            if tagConfig!.lockWidth!
            {
                totalW = tagConfig!.itemWidth! * CGFloat(sectionCountArr[j]) + tagConfig!.itemHerMargin! * CGFloat(sectionCountArr[j] - 1)
                currentSectionTotalW = totalW
            }
            else
            {
                let a = (j == 0) ? 0 : (rowLastTagArr[j - 1] + 1)
                if a < self.rowLastTagArr[j]
                {
                    for i in a...(rowLastTagArr[j] + 1)
                    {
                        let currentBtn = self.viewWithTag(i + BTN_Tags_Tag) as! BKLayoutButton
                        totalW += currentBtn.frame.width
                    }
                }
                currentSectionTotalW = totalW + tagConfig!.itemHerMargin! * CGFloat(sectionCountArr[j] + 1)
            }
                        
            var xxxxx : CGFloat = 0
            switch position {
            case .Left:
                xxxxx = tagConfig!.itemHerMargin!
            case .Center:
                if (kSCREEN_WIDTH - currentSectionTotalW) < 0
                {
                    xxxxx = 0
                }
                else
                {
                    if tagConfig!.LastRowCenter!
                    {
                        xxxxx = (kSCREEN_WIDTH - currentSectionTotalW) / 2
                    }
                    else
                    {
                        if j == section
                        {
                            if section == 0
                            {
                                if tagConfig!.lockWidth!
                                {
                                    let c = floor(kSCREEN_WIDTH / (tagConfig!.itemWidth! + tagConfig!.itemHerMargin!))
                                    xxxxx = (kSCREEN_WIDTH - (tagConfig!.itemWidth! * CGFloat(c) + tagConfig!.itemHerMargin! * CGFloat(c - 1)))/2
                                }
                                else
                                {
                                    xxxxx = tagConfig!.itemHerMargin! * 2
                                }
                            }
                            else
                            {
                                xxxxx = (kSCREEN_WIDTH - (tagConfig!.itemWidth! * CGFloat(sectionCountArr[j - 1]) + tagConfig!.itemHerMargin! * CGFloat(sectionCountArr[j - 1] - 1)))/2
                            }
                        }
                        else
                        {
                            xxxxx = (kSCREEN_WIDTH - currentSectionTotalW) / 2
                        }
                    }
//                    if tagConfig!.titleNormal!.count == 1
//                    {
//                        xxxxx = (kScreenWidth - tagConfig!.itemWidth!) / 2
//                    }
//                    else
//                    {
//                        if  j == section
//                        {
//                            if section == 0
//                            {
//                                xxxxx = (kScreenWidth - (tagConfig!.itemWidth! * CGFloat(sectionCountArr[0]) + tagConfig!.itemHerMargin! * CGFloat(sectionCountArr[0] - 1)))/2
//                            }
//                            else
//                            {
//                                xxxxx = (kScreenWidth - (tagConfig!.itemWidth! * CGFloat(sectionCountArr[j - 1]) + tagConfig!.itemHerMargin! * CGFloat(sectionCountArr[j - 1] - 1)))/2
//                            }
//                        }
//                        else
//                        {
//                            xxxxx = (kScreenWidth - currentSectionTotalW) / 2
//                        }
//                    }
                }
            case .Right:
                xxxxx = kSCREEN_WIDTH - currentSectionTotalW + tagConfig!.itemHerMargin!
            }
            
            let a = (j == 0) ? 0 : (rowLastTagArr[j - 1] + 1)
            if a > self.rowLastTagArr[j]
            {
                for i in stride(from: a, to: self.rowLastTagArr[j] + 1, by: -1)
                {
                    guard let currentBtn = self.viewWithTag(i + BTN_Tags_Tag) else { return }
                    if i == a
                    {
                        currentBtn.frame = CGRect.init(x: xxxxx, y: currentBtn.frame.origin.y, width: currentBtn.frame.size.width, height: currentBtn.frame.size.height)
                    }
                    else
                    {
                        guard let lastBtn = self.viewWithTag(i - 1 + BTN_Tags_Tag) else{ return }
                        currentBtn.frame = CGRect.init(x: lastBtn.frame.origin.x + lastBtn.frame.size.width + tagConfig!.itemHerMargin!, y: currentBtn.frame.origin.y, width: currentBtn.frame.size.width, height: currentBtn.frame.size.height)
                    }
                }
            }
            else
            {
                for i in a...(self.rowLastTagArr[j])
                {
                    let currentBtn = self.viewWithTag(i + BTN_Tags_Tag) as! BKLayoutButton
                    
                    if i == a
                    {
                        currentBtn.frame = CGRect.init(x: xxxxx, y: currentBtn.frame.origin.y, width: currentBtn.frame.size.width, height: currentBtn.frame.size.height)
                    }
                    else
                    {
                        guard let lastBtn = self.viewWithTag(i - 1 + BTN_Tags_Tag) else{ return }
                        currentBtn.frame = CGRect.init(x: lastBtn.frame.origin.x + lastBtn.frame.size.width + tagConfig!.itemHerMargin!, y: currentBtn.frame.origin.y, width: currentBtn.frame.size.width, height: currentBtn.frame.size.height)
                    }
                }
            }
        }
    }
    
    func clearTag()
    {
        self.tagsTitleArr.enumerated().forEach { (index,value) in
            let btn = self.viewWithTag(index + BTN_Tags_Tag) as! BKLayoutButton
            btn.isSelected = false
            btn.backgroundColor = self.tagConfig!.backgroundColor!
            if self.tagConfig!.hasBorder!
            {
                btn.layer.borderColor = self.tagConfig!.borderColor!.cgColor
            }
        }
    }
}
