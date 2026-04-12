//  Copyright © 2018-2020 App Dev Guy. All rights reserved.
//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

import AVFoundation

/// OSSUtterance is a wrapper of the AVSpeechUtterance class.
///
/// The OSSUtterance offers special overrides for strings which are usually set once objects.
///
/// As the developer, you can override the `volume`, `rate` and `pitchMultiplier` should you wish to.
public class OSSUtterance: AVSpeechUtterance {

    // MARK: - Variables
    
    // 【优化 1】移除默认的空值分配，使用私有变量作为底层存储。
    // 这避免了在实例化时无意义的内存开销。
    private var _stringToSpeak: String
    private var _attributedStringToSpeak: NSAttributedString

    /// The speechString can be a constant value or changed as frequently as you wish.
    override public var speechString: String {
        get {
            return _stringToSpeak
        }
        set {
            // 【优化 2】添加防抖判断：如果新值和旧值一样，则不执行任何操作。
            // 避免频繁、重复地创建 NSAttributedString 对象。
            guard _stringToSpeak != newValue else { return }
            
            _stringToSpeak = newValue
            _attributedStringToSpeak = NSAttributedString(string: newValue)
        }
    }

    /// The attributedSpeechString can be a constant value or changed as frequently as you wish.
    override public var attributedSpeechString: NSAttributedString {
        get {
            return _attributedStringToSpeak
        }
        set {
            // 同理，添加相等性判断
            guard _attributedStringToSpeak != newValue else { return }
            
            _attributedStringToSpeak = newValue
            _stringToSpeak = newValue.string
        }
    }

    // MARK: - Lifecycle

    public override init() {
        // 【优化 4】Swift 初始化规则：先初始化子类的属性，再调用父类的 designated initializer。
        self._stringToSpeak = "ERROR"
        self._attributedStringToSpeak = NSAttributedString(string: "ERROR")
        super.init(string: "ERROR")
        
        // 假设这里是你自定义的日志系统
        // PTNSLogConsole("ERROR: You must use the `init(string:)` or `init(attributedString:` methods.",levelType: .error,loggerType: .speech)
        
        commonInit()
    }

    /// Init method which will set the speechString value.
    public override init(string: String) {
        self._stringToSpeak = string
        self._attributedStringToSpeak = NSAttributedString(string: string)
        super.init(string: string)
        
        commonInit()
    }

    /// Init method which will set the attributedSpeechString value.
    public override init(attributedString: NSAttributedString) {
        self._stringToSpeak = attributedString.string
        self._attributedStringToSpeak = attributedString
        super.init(attributedString: attributedString)
        
        commonInit()
    }

    /// Required. Do not recommend using.
    public required init?(coder aDecoder: NSCoder) {
        // 【优化 3】修复 NSCoder Bug。不支持序列化时，应直接抛出 fatalError。
        // 原来的 super.init() + return nil 违反了 init(coder:) 的初始化规则。
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods

    /// Common init is used for testing purposes only.
    private func commonInit() {
        // Init default values
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitchMultiplier = 1.0
        volume = 1.0
        
        // 【温馨提示】Alex 是高质量男声（体积较大），且仅限美式英语 (en-US)。
        // 如果用户的设备没有下载该声音，或者你的文本是其他语言（如中文），它可能会回退到默认声音。
        voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
    }
}
