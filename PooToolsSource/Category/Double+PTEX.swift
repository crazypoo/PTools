//
//  Double+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/8.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension Double
{
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
    func valueAddUnitToString(unit:Unit)->String
    {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.init(identifier: "zh")
        formatter.unitOptions = .providedUnit
        
        let measurement = Measurement(value: self, unit: unit)
        return formatter.string(from: measurement)
    }
}
