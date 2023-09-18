//
//  Double+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/8.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension Double:PTProtocolCompatible {}

public extension Double {
    /*
     加速度单位 NSUnitAccelerationm /s²
     几何角度单位 NSUnitAngle度（°）
     面积单位 NSUnitArea平方米（m²）
     单元集中质量（密度 NSUnitConcentrationMass毫克/分升（mg / dL）
     单位分散 NSUnitDispersion百万分率（ppm）
     单位时间 NSUnitDuration秒（s）
     单位电荷 NSUnitElectricCharge库仑（C）
     单位电流 NSUnitElectricCurrent安（A）
     单位电位差（电压）NSUnitElectricCurrent伏特（V）
     单元电阻 NSUnitElectricResistance欧姆（Ω）
     单位能量 NSUnitEnergy焦耳（J）
     单位频率 NSUnitFrequency赫兹（赫兹）
     单位燃料效率 NSUnitFuelEfficiency每百公里升（L / 100km）
     单位长度 NSUnitLength米（m）
     单位照度 NSUnitIlluminance勒克斯（lx）
     单位质量 NSUnitMass千克（kg）
     单位功率 NSUnitPower瓦特（W）
     单位压力（压强） NSUnitPressure牛顿每平方米（N /m²）
     单位速度 NSUnitSpeed米/秒（m / s）
     单位温度 NSUnitTemperature开尔文（K）
     单位体积 NSUnitVolume升（L）
     */
    //MARK: 物理單位獲取
    ///物理單位獲取
    func valueAddUnitToString(unit:Unit)->String {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.init(identifier: "zh")
        formatter.unitOptions = .providedUnit
        
        let measurement = Measurement(value: self, unit: unit)
        return formatter.string(from: measurement)
    }
    
    //MARK: 數字金額轉換成人民幣大寫金額
    /// - Parameter return: 人民幣大寫金額
    func cnySpellOut()->String {
        let numString = String(format: "%.2f", self)
        let parts = numString.split(separator: ".")
        let integerPart = parts[0]
        let fractionalPart = parts[1]
        let chineseNumerals = ["零", "壹", "貳", "參", "肆", "伍", "陸", "柒", "捌", "玖"]
        let chineseUnits = ["", "拾", "佰", "仟", "萬", "拾萬", "佰萬", "仟萬", "億", "拾億", "佰億", "仟億"]
        let chineseFractionalUnits = ["角", "分"]
        var integerString = ""
        var count = 0
        for i in (0..<integerPart.count).reversed() {
            let index = integerPart.index(integerPart.startIndex, offsetBy: i)
            let ch = chineseNumerals[Int(String(integerPart[index]))!]
            let unit = chineseUnits[count % chineseUnits.count]
            if ch != "零" {
                integerString = ch + unit + integerString
            } else if !integerString.isEmpty {
                integerString = ch + integerString
            }
            count += 1
        }
        var fractionalString = ""
        count = 0
        for i in 0..<2 {
            let index = fractionalPart.index(fractionalPart.startIndex, offsetBy: i)
            let ch = chineseNumerals[Int(String(fractionalPart[index]))!]
            let unit = chineseFractionalUnits[count]
            if ch != "零" {
                fractionalString += ch + unit
            }
            count += 1
        }
        if integerString.isEmpty {
            integerString = "零"
        }
        if fractionalString.isEmpty {
            return integerString + "元整"
        } else {
            return integerString + "元" + fractionalString
        }
    }
    
    //MARK: 角度转弧度
    ///角度转弧度
    /// - Returns: 弧度
    func degreesToRadians() -> Double {
        (.pi * self) / 180.0
    }
    
    //MARK: 弧度转角度
    ///角弧度转角度
    /// - Returns: 角度
    func radiansToDegrees() -> Double {
        (self * 180.0) / .pi
    }
    
    //MARK:  浮点数四舍五入
    ///浮点数四舍五入
    /// - Parameters:
    ///  - places: 数字
    /// - Returns: Double
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

public extension PTPOP where Base == Double {
    // MARK: 转 NSNumber
    /// 转 NSNumber
    var number: NSNumber { 
        return NSNumber(value: self.base)
    }
}
