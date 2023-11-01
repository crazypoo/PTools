//
//  UILabel+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension UILabel {
    private struct AssociatedKey {
        static var startTime: CFTimeInterval = 0
        static var fromValue: Double = 0
        static var toValue: Double = 0
        static var duration: Double = 0
        static var displayLink: UnsafeRawPointer = UnsafeRawPointer(bitPattern: "displayLink".hashValue)!
        static var formatter = 998
    }
    private var startTime: CFTimeInterval {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.startTime) as? CFTimeInterval ?? 0
        } set {
            objc_setAssociatedObject(self, &AssociatedKey.startTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var fromValue: Double {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.fromValue) as? Double ?? 0
        } set {
            objc_setAssociatedObject(self, &AssociatedKey.fromValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var toValue: Double {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.toValue) as? Double ?? 0
        } set {
            objc_setAssociatedObject(self, &AssociatedKey.toValue, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var duration: Double {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.duration) as? Double ?? 0
        } set {
            objc_setAssociatedObject(self, &AssociatedKey.duration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var displayLink: CADisplayLink? {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.displayLink) as? CADisplayLink
        } set {
            objc_setAssociatedObject(self, &AssociatedKey.displayLink, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    private var formatter: String? {
        get {
            objc_getAssociatedObject(self, &AssociatedKey.formatter) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.formatter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    //MARK: 數字跳動
    ///數字跳動
    /// - Parameters:
    ///   - fromValue: 從什麼數值開始
    ///   - to: 到哪個數值
    ///   - duration: 動畫時間
    ///   - formatter: 格式化(默認".2f")
    @objc func count(fromValue: Double,
                     to: Double,
                     duration: Double,
                     formatter:String? = "%.2f") {
        startTime = CACurrentMediaTime()
        self.fromValue = fromValue
        toValue = to
        self.duration = duration
        self.formatter = formatter
        displayLink = CADisplayLink(target: self, selector: #selector(updateValue))
        displayLink?.add(to: .main, forMode: .default)
    }
    
    @objc private func updateValue() {
        let now = CACurrentMediaTime()
        let elapsedTime = now - startTime
        if elapsedTime > duration {
            text = String(format: formatter! as String, toValue)
            displayLink?.invalidate()
            return
        }
        let percentage = elapsedTime / duration
        let value = fromValue + percentage * (toValue - fromValue)
        
        text = String(format: formatter! as String, value)
    }
    
    //MARK: 計算文字的Size
    ///計算文字的Size
    /// - Parameters:
    ///   - lineSpacing: 行距
    ///   - size: size
    /// - Returns: Size
    @objc func sizeFor(lineSpacing:NSNumber? = nil,
                       size:CGSize)->CGSize {
        var dic = [NSAttributedString.Key.font: font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = CGFloat(lineSpacing!.floatValue)
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = text!.boundingRect(with: CGSize.init(width: size.width, height: size.height), options: [.usesLineFragmentOrigin,.usesDeviceMetrics], attributes: dic, context: nil).size
        return size
    }
}

//MARK: 其他的基本扩展
public extension PTPOP where Base: UILabel {
    
    //MARK: 获取已知 frame 的 label 的文本行数 & 每一行内容
    ///获取已知 frame 的 label 的文本行数 & 每一行内容
    /// - Parameters:
    ///   - lineSpace: 行间距
    ///   - textSpace: 字间距，默认为0.0
    ///   - paraSpace: 段间距，默认为0.0
    /// - Returns: label 的文本行数 & 每一行内容
    func linesCountAndLinesContent(lineSpace: CGFloat, 
                                   textSpace: CGFloat = 0.0,
                                   paraSpace: CGFloat = 0.0) -> (Int?, [String]?) {
        accordWidthLinesCountAndLinesContent(accordWidth: base.frame.size.width, lineSpace: lineSpace, textSpace: textSpace, paraSpace: paraSpace)
    }
    
    //MARK: 获取已知 width 的 label 的文本行数 & 每一行内容
    ///获取已知 width 的 label 的文本行数 & 每一行内容
    /// - Parameters:
    ///   - accordWidth: label 的 width
    ///   - lineSpace: 行间距
    ///   - textSpace: 字间距，默认为0.0
    ///   - paraSpace: 段间距，默认为0.0
    /// - Returns: description
    func accordWidthLinesCountAndLinesContent(accordWidth: CGFloat, 
                                              lineSpace: CGFloat,
                                              textSpace: CGFloat = 0.0,
                                              paraSpace: CGFloat = 0.0) -> (Int?, [String]?) {
        guard let t = base.text, let f = base.font else {return (0, nil)}
        let align = base.textAlignment
        let c_fn = f.fontName as CFString
        let fp = f.pointSize
        let c_f = CTFontCreateWithName(c_fn, fp, nil)
        
        let contentDict = UILabel.pt.genTextStyle(text: t as NSString, linebreakmode: NSLineBreakMode.byCharWrapping, align: align, font: f, lineSpace: lineSpace, textSpace: textSpace, paraSpace: paraSpace)
        
        let attr = NSMutableAttributedString(string: t)
        let range = NSRange(location: 0, length: attr.length)
        attr.addAttributes(contentDict, range: range)
        
        attr.addAttribute(NSAttributedString.Key.font, value: c_f, range: range)
        let frameSetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        
        let path = CGMutablePath()
        /// 2.5 是经验误差值
        path.addRect(CGRect(x: 0, y: 0, width: accordWidth - 2.5, height: CGFloat(MAXFLOAT)))
        let framef = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        let lines = CTFrameGetLines(framef) as NSArray
        var lineArr = [String]()
        for line in lines {
            let lineRange = CTLineGetStringRange(line as! CTLine)
            let lineString = t.sub(start: lineRange.location,length: lineRange.length)
            lineArr.append(lineString as String)
        }
        return (lineArr.count, lineArr)
    }
    
    //MARK: 获取第一行内容
    ///获取第一行内容
    var firstLineString: String? {
        self.linesCountAndLinesContent(lineSpace: 0.0).1?.first
    }
    
    //MARK: 改变行间距
    ///改变行间距
    /// - Parameters:
    ///  - space: 行间距大小
    func changeLineSpace(space: CGFloat) {
        if base.text == nil || base.text == "" {
            return
        }
        let text = base.text
        let attributedString = NSMutableAttributedString(string: text!)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = space
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: text!.count))
        self.base.attributedText = attributedString
        base.sizeToFit()
    }
    
    //MARK: 改变字间距
    ///改变字间距
    /// - Parameters:
    ///  -  space: 字间距大小
    func changeWordSpace(space: CGFloat) {
        if base.text == nil || base.text == "" {
            return
        }
        let text = base.text
        let attributedString = NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.kern:space])
        let paragraphStyle = NSMutableParagraphStyle()
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: text!.count))
        self.base.attributedText = attributedString
        base.sizeToFit()
    }
    
    //MARK: 改变字间距和行间距
    ///改变字间距和行间距
    /// - Parameters:
    ///   - lineSpace: 行间距
    ///   - wordSpace: 字间距
    func changeSpace(lineSpace: CGFloat, 
                     wordSpace: CGFloat) {
        if base.text == nil || base.text == "" {
            return
        }
        let text = base.text
        let attributedString = NSMutableAttributedString(string: text!, attributes: [NSAttributedString.Key.kern:wordSpace])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpace
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: text!.count))
        self.base.attributedText = attributedString
        base.sizeToFit()
    }
    
    //MARK: label添加中划线
    ///label添加中划线
    /// - Parameters:
    ///   - lineValue: value 越大,划线越粗
    ///   - underlineColor: 中划线的颜色
    func centerLineText(lineValue: Int = 1, 
                        underlineColor: UIColor = .black) {
        guard let content = base.text else {
            return
        }
        let arrText = NSMutableAttributedString(string: content)
        arrText.addAttributes([NSAttributedString.Key.strikethroughStyle: lineValue, NSAttributedString.Key.strikethroughColor: underlineColor], range: NSRange(location: 0, length: arrText.length))
        base.attributedText = arrText
    }
    
    //MARK: 设置文本样式
    ///设置文本样式
    /// - Parameters:
    ///   - text: 文字内容
    ///   - linebreakmode: 结尾部分的内容以……方式省略 ( "...wxyz" ,"abcd..." ,"ab...yz")
    ///   - align: 文本对齐方式：（左，中，右，两端对齐，自然）
    ///   - font: 字体大小
    ///   - lineSpace: 字体的行间距
    ///   - textSpace: 设定字符间距，取值为 NSNumber 对象（整数），正值间距加宽，负值间距变窄
    ///   - paraSpace: 段与段之间的间距
    /// - Returns: 返回样式 [NSAttributedString.Key : Any]
    private static func genTextStyle(text: NSString, 
                                     linebreakmode: NSLineBreakMode,
                                     align: NSTextAlignment,
                                     font: UIFont,
                                     lineSpace: CGFloat,
                                     textSpace: CGFloat,
                                     paraSpace: CGFloat) -> [NSAttributedString.Key : Any] {
        let style = NSMutableParagraphStyle()
        // 结尾部分的内容以……方式省略 ( "...wxyz" ,"abcd..." ,"ab...yz")
        /**
         case byWordWrapping = 0       //  以单词为显示单位显示，后面部分省略不显示
         case byCharWrapping = 1        //  以字符为显示单位显示，后面部分省略不显示
         case byClipping = 2                  //  剪切与文本宽度相同的内容长度，后半部分被删除
         case byTruncatingHead = 3      //  前面部分文字以……方式省略，显示尾部文字内容
         case byTruncatingTail = 4         //  结尾部分的内容以……方式省略，显示头的文字内容
         case byTruncatingMiddle = 5    //  中间的内容以……方式省略，显示头尾的文字内容
         */
        style.lineBreakMode = linebreakmode
        // 文本对齐方式：（左，中，右，两端对齐，自然）
        style.alignment = align
        // 字体的行间距
        style.lineSpacing = lineSpace
        // 连字属性 在iOS，唯一支持的值分别为0和1
        style.hyphenationFactor = 1.0
        // 首行缩进
        style.firstLineHeadIndent = 0.0
        // 段与段之间的间距
        style.paragraphSpacing = paraSpace
        // 段首行空白空间
        style.paragraphSpacingBefore = 0.0
        // 整体缩进(首行除外)
        style.headIndent = 0.0
        // 文本行末缩进距离
        style.tailIndent = 0.0
        
        /*
         // 一组NSTextTabs。 内容应按位置排序。 默认值是一个由12个左对齐制表符组成的数组，间隔为28pt ？？？？？
         style.tabStops =
         // 一个布尔值，指示系统在截断文本之前是否可以收紧字符间间距 ？？？？？
         style.allowsDefaultTighteningForTruncation = true
         // 文档范围的默认选项卡间隔 ？？？？？
         style.defaultTabInterval = 1
         // 最低行高（设置最低行高后，如果文本小于20行，会通过增加行间距达到20行的高度）
         style.minimumLineHeight = 10
         // 最高行高（设置最高行高后，如果文本大于10行，会通过降低行间距达到10行的高度）
         style.maximumLineHeight = 20
         //从左到右的书写方向
         style.baseWritingDirection = .leftToRight
         // 在受到最小和最大行高约束之前，自然线高度乘以该因子（如果为正） 多少倍行间距
         style.lineHeightMultiple = 15
         */
        
        let dict = [
            NSAttributedString.Key.font : font, NSAttributedString.Key.paragraphStyle : style, NSAttributedString.Key.kern : textSpace] as [NSAttributedString.Key : Any]
        return dict
    }
    
    //MARK: 获取已知label的文本行数和每一行内容
    ///获取已知label的文本行数和每一行内容
    /// - Returns: 每行的内容
    func linesCountAndLinesContent() -> (Int?, [String]?) {
        guard let t = base.text else {return (0, nil)}
        let lodFontName = base.font.fontName == ".SFUI-Regular" ? "TimesNewRomanPSMT" : base.font.fontName
        let fontSize = getFontSizeForLabel()
        let newFont = UIFont(name: lodFontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let c_fn = newFont.fontName as CFString
        let fp = newFont.pointSize
        let c_f = CTFontCreateWithName(c_fn, fp, nil)
 
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byCharWrapping
        let contentDict = [NSAttributedString.Key.paragraphStyle : style] as [NSAttributedString.Key : Any]
        
        let attr = NSMutableAttributedString(string: t)
        let range = NSRange(location: 0, length: attr.length)
        attr.addAttributes(contentDict, range: range)
        attr.addAttribute(NSAttributedString.Key.font, value: c_f, range: range)
        let frameSetter = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        
        let path = CGMutablePath()
        /// 2.5 是经验误差值
        path.addRect(CGRect(x: 0, y: 0, width: base.pt.jx_width, height: base.pt.jx_height > (fp * 1.5) ? base.pt.jx_height : fp * 1.5))
        let framef = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
        let lines = CTFrameGetLines(framef) as NSArray
        var lineArr = [String]()
        for line in lines {
            let lineRange = CTLineGetStringRange(line as! CTLine)
            let lineString = t.sub(start: lineRange.location, length: lineRange.length)
            lineArr.append(lineString as String)
        }
        return (lineArr.count, lineArr)
    }
    
    //MARK: 获取字体的大小
    ///获取字体的大小
    /// - Returns: 字体大小
    func getFontSizeForLabel() -> CGFloat {
        let text: NSMutableAttributedString = NSMutableAttributedString(attributedString: base.attributedText!)
        text.setAttributes([NSAttributedString.Key.font: base.font as Any], range: NSMakeRange(0, text.length))
        let context: NSStringDrawingContext = NSStringDrawingContext()
        context.minimumScaleFactor = base.minimumScaleFactor
        text.boundingRect(with: base.frame.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, context: context)
        let adjustedFontSize: CGFloat = base.font.pointSize * context.actualScaleFactor
        return adjustedFontSize
    }
}
