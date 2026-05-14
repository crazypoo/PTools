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

/// 采用内部递归锁确保线程安全的定制 Utterance 类
public class OSSUtterance: AVSpeechUtterance, @unchecked Sendable {

    private var _stringToSpeak: String
    private var _attributedStringToSpeak: NSAttributedString
    private let lock = NSRecursiveLock()

    override public var speechString: String {
        get { lock.withLock { _stringToSpeak } }
        set {
            lock.withLock {
                guard _stringToSpeak != newValue else { return }
                _stringToSpeak = newValue
                _attributedStringToSpeak = NSAttributedString(string: newValue)
            }
        }
    }

    override public var attributedSpeechString: NSAttributedString {
        get { lock.withLock { _attributedStringToSpeak } }
        set {
            lock.withLock {
                guard _attributedStringToSpeak != newValue else { return }
                _attributedStringToSpeak = newValue
                _stringToSpeak = newValue.string
            }
        }
    }

    public override init() {
        self._stringToSpeak = "ERROR"
        self._attributedStringToSpeak = NSAttributedString(string: "ERROR")
        super.init(string: "ERROR")
        commonInit()
    }

    public override init(string: String) {
        self._stringToSpeak = string
        self._attributedStringToSpeak = NSAttributedString(string: string)
        super.init(string: string)
        commonInit()
    }

    public override init(attributedString: NSAttributedString) {
        self._stringToSpeak = attributedString.string
        self._attributedStringToSpeak = attributedString
        super.init(attributedString: attributedString)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        rate = AVSpeechUtteranceDefaultSpeechRate
        pitchMultiplier = 1.0
        volume = 1.0
        voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
    }
}
