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

import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 保证数据结构的一致性，已升级为严格 Sendable 兼容
public struct OSSVoiceInfo: Sendable {
    public var name: String?
    public var language: String?
    public var languageCode: String?
    // 【修复】将 Any? 改为 String? 以符合 Swift 6 Sendable 协议
    public var identifier: String?
}

// swiftlint:disable identifier_name
public enum OSSVoiceEnum: String, CaseIterable, Sendable {
    case Australian = "en-AU"
    case Brazilian = "pt-BR"
    case Bulgarian = "bg-BG"
    case CanadianFrench = "fr-CA"
    case Chinese = "zh-CH"
    case ChineseSimplified = "zh-CN"
    case ChineseHongKong = "zh-HK"
    case Croatian = "hr-HR"
    case Czech = "cs-CZ"
    case Danish = "da-DK"
    case DutchBelgium = "nl-BE"
    case DutchNetherlands = "nl-NL"
    case English = "en-GB"
    case Finnish = "fi-FI"
    case French = "fr-FR"
    case German = "de-DE"
    case Greek = "el-GR"
    case Hebrew = "he-IL"
    case Hindi = "hi-IN"
    case Hungarian = "hu-HU"
    case IndianEnglish = "en-IN"
    case Indonesian = "id-ID"
    case IrishEnglish = "en-IE"
    case Italian = "it-IT"
    case Japanese = "ja-JP"
    case Korean = "ko-KR"
    case Malay = "ms-MY"
    case Mexican = "es-MX"
    case Norwegian = "no-NO"
    case NorwegianBokmal = "nb-NO"
    case Polish = "pl-PL"
    case Portuguese = "pt-PT"
    case Romanian = "ro-RO"
    case Russian = "ru-RU"
    case SaudiArabian = "ar-SA"
    case Slovakian = "sk-SK"
    case SouthAfricanEnglish = "en-ZA"
    case Spanish = "es-ES"
    case SpanishCatalan = "ca-ES"
    case Swedish = "sv-SE"
    case Taiwanese  = "zh-TW"
    case Thai = "th-TH"
    case Turkish = "tr-TR"
    case Ukranian = "uk-UA"
    case UnitedStatesEnglish = "en-US"
    case Vietnamese = "vi-VN"
    case ArabicWorld = "ar-001"

    public func getDetails() -> OSSVoiceInfo {
        var voiceInfo = OSSVoiceInfo()
        if let voice = AVSpeechSynthesisVoice(language: rawValue) {
            voiceInfo.name = voice.name
            voiceInfo.identifier = voice.identifier // 原生 identifier 本身就是 String
            voiceInfo.languageCode = rawValue
            voiceInfo.language = "\(self)"
        }
        return voiceInfo
    }

    public var title: String {
        String(describing: self)
    }

    public var demoMessage: String {
        let voiceName = getDetails().name ?? ""
        switch self {
        case .SaudiArabian, .ArabicWorld: return "\(voiceName) مرحبا اسمي"
        case .Czech: return "Dobrý den, jmenuji se \(voiceName)"
        case .Danish: return "Hej, mit navn er \(voiceName)"
        case .German: return "Hallo, Ich heisse \(voiceName)"
        case .Greek: return "Γεια το όνομά μου είναι \(voiceName)"
        case .Australian, .English, .IrishEnglish, .UnitedStatesEnglish, .SouthAfricanEnglish, .IndianEnglish:
            return "Hello, my name is \(voiceName)"
        case .Spanish, .Mexican: return "Hola, mi nombre es \(voiceName)"
        case .Finnish: return "Hei, minun nimeni on \(voiceName)"
        case .CanadianFrench, .French: return "Bonjour, mon nom est \(voiceName)"
        case .Hebrew: return "\(voiceName)שלום שמי הוא"
        case .Hindi: return "नमस्ते मेरा नाम है \(voiceName)"
        case .Hungarian: return "Helló, az én nevem \(voiceName)"
        case .Indonesian: return "Halo, namaku adalah \(voiceName)"
        case .Italian: return "Ciao, il mio nome è \(voiceName)"
        case .Japanese: return "こんにちは、私の名前は \(voiceName)"
        case .Korean: return "안녕 내 이름은 \(voiceName)"
        case .DutchBelgium, .DutchNetherlands: return "Hallo, mijn naam is \(voiceName)"
        case .Norwegian, .NorwegianBokmal: return "Hei, mitt navn er \(voiceName)"
        case .Polish: return "Cześć, mam na imię \(voiceName)"
        case .Brazilian, .Portuguese: return "Olá meu nome é \(voiceName)"
        case .Romanian: return "Buna numele meu este \(voiceName)"
        case .Russian: return "Привет меня зовут \(voiceName)"
        case .Slovakian: return "Ahoj volám sa \(voiceName)"
        case .Swedish: return "Hej mitt namn är \(voiceName)"
        case .Thai: return "สวัสดีฉันชื่อ \(voiceName)"
        case .Turkish: return "Merhaba benim adım \(voiceName)"
        case .Chinese, .ChineseHongKong, .Taiwanese, .ChineseSimplified: return "你好我的名字是 \(voiceName)"
        case .Bulgarian: return "Здравейте, казвам се \(voiceName)"
        case .Croatian: return "Zdravo! Moje ime je \(voiceName)"
        case .Malay: return "helo! Nama saya \(voiceName)"
        case .SpanishCatalan: return "Hola! Em dic \(voiceName)"
        case .Ukranian: return "Привіт! Мене звати \(voiceName)"
        case .Vietnamese: return "Xin chào! Tên của tôi là \(voiceName)"
        }
    }

#if canImport(UIKit)
    public var flag: UIImage? {
        if let mainBundleImage = UIImage(named: rawValue, in: Bundle.main, compatibleWith: nil) {
            return mainBundleImage
        }
        // 需确保上游存在 Bundle.podBundleImage 实现
        return UIImage(named: rawValue)
    }
#elseif canImport(AppKit)
    public var flag: NSImage? {
        return NSImage(named: rawValue)
    }
#endif
}

/// 采用内部递归锁确保线程安全的定制 Voice 类
public class OSSVoice: AVSpeechSynthesisVoice, @unchecked Sendable {

    private var voiceQuality: AVSpeechSynthesisVoiceQuality = .default
    private var voiceLanguage: String = OSSVoiceEnum.UnitedStatesEnglish.rawValue
    private var voiceTypeValue: OSSVoiceEnum = .UnitedStatesEnglish
    
    // 【Swift 6 优化】使用互斥递归锁保护内部可变状态
    private let lock = NSRecursiveLock()

    override public var quality: AVSpeechSynthesisVoiceQuality {
        get { lock.withLock { voiceQuality } }
        set { lock.withLock { voiceQuality = newValue } }
    }

    override public var language: String {
        get { lock.withLock { voiceLanguage } }
        set {
            lock.withLock {
                voiceLanguage = newValue
                if let valueEnum = OSSVoiceEnum(rawValue: newValue) {
                    voiceTypeValue = valueEnum
                }
            }
        }
    }

    public var voiceType: OSSVoiceEnum {
        lock.withLock { voiceTypeValue }
    }

    public override init() {
        super.init()
        commonInit()
    }

    public init?(quality: AVSpeechSynthesisVoiceQuality, language: OSSVoiceEnum) {
        super.init()
        lock.withLock {
            voiceTypeValue = language
            voiceLanguage = language.rawValue
            voiceQuality = quality
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        return nil
    }

    private func commonInit() {
        lock.withLock {
            voiceTypeValue = OSSVoiceEnum.UnitedStatesEnglish
            voiceLanguage = OSSVoiceEnum.UnitedStatesEnglish.rawValue
            voiceQuality = .default
        }
    }
}
