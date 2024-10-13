//
//  UIStepper+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIStepper {
    
    convenience init(frame: CGRect = .zero, options: Options) {
        self.init(frame: frame)
        
        applyOptions(options)
    }
}

public extension UIStepper {
    
    func applyOptions(_ options: Options) {
        value        = options.value
        minimumValue = options.minimumValue
        maximumValue = options.maximumValue
        stepValue    = options.stepValue
        isContinuous = options.isContinuous
        autorepeat   = options.autorepeat
        wraps        = options.wraps
    }
    
    /// An object that defines the appearance of a UIStepper.
    struct Options: Equatable {
        /**
         The continuous vs. noncontinuous state of the stepper.
         
         If `true`, value change events are sent immediately when the value changes during user interaction. If `false`, a value change event is sent when user interaction ends.
         
         The default value for this property is `true`.
        */
        public var isContinuous: Bool
        
        /**
         The automatic vs. nonautomatic repeat state of the stepper.
         
         If `true`, the user pressing and holding on the stepper repeatedly alters value.
         
         The default value for this property is `true`.
        */
        public var autorepeat: Bool
        
        /**
         The wrap vs. no-wrap state of the stepper.
         
         If `true`, incrementing beyond maximumValue sets value to minimumValue; likewise, decrementing below minimumValue sets value to maximumValue. If `false`, the stepper does not increment beyond maximumValue nor does it decrement below minimumValue but rather holds at those values.
         
         The default value for this property is `false`.
        */
        public var wraps: Bool
        
        /**
         The numeric value of the stepper.
         
         When the value changes, the stepper sends the valueChanged flag to its target (see addTarget(_:action:for:)). Refer to the description of the isContinuous property for information about whether value change events are sent continuously or when user interaction ends.
         
         This property is clamped at its lower extreme to minimumValue and is clamped at its upper extreme to maximumValue.
         */
        public var value: Double
        
        /**
         The lowest possible numeric value for the stepper.
         
         Must be numerically less than maximumValue. If you attempt to set a value equal to or greater than maximumValue, the system raises an [invalidArgumentException](apple-reference-documentation://hsX4-I43qu) exception.
         */
        public var minimumValue: Double
        /**
         The highest possible numeric value for the stepper.
         
         Must be numerically greater than minimumValue. If you attempt to set a value equal to or lower than minimumValue, the system raises an [invalidArgumentException](apple-reference-documentation://hsX4-I43qu) exception.
         */
        public var maximumValue: Double
        
        /**
         The step, or increment, value for the stepper.
         
         Must be numerically greater than `0`. If you attempt to set this property’s value to `0` or to a negative number, the system raises an [invalidArgumentException](apple-reference-documentation://hsX4-I43qu) exception.
         
         The default value for this property is `1`.
         */
        public var stepValue: Double
        
        /// Initializes a UIStepper configurator object.
        /// - Parameters:
        ///   - value: The numeric value of the stepper.
        ///   - minimumValue: The lowest possible numeric value for the stepper.
        ///   - maximumValue: The highest possible numeric value for the stepper.
        ///   - stepValue: The step, or increment, value for the stepper.
        ///   - isContinuous: The continuous vs. noncontinuous state of the stepper.
        ///   - autorepeat: The automatic vs. nonautomatic repeat state of the stepper.
        ///   - wraps: The wrap vs. no-wrap state of the stepper.
        public init(
            value: Double,
            minimumValue: Double,
            maximumValue: Double,
            stepValue: Double = 1,
            isContinuous: Bool = true,
            autorepeat: Bool = true,
            wraps: Bool = false
        ) {
            self.value        = value
            self.minimumValue = minimumValue
            self.maximumValue = maximumValue
            self.stepValue    = stepValue
            self.isContinuous = isContinuous
            self.autorepeat   = autorepeat
            self.wraps        = wraps
        }
        
        /// Initializes a UIStepper configurator object.
        /// - Parameters:
        ///   - value: The numeric value of the stepper.
        ///   - minimumValue: The lowest possible numeric value for the stepper.
        ///   - maximumValue: The highest possible numeric value for the stepper.
        ///   - stepValue: The step, or increment, value for the stepper.
        ///   - isContinuous: The continuous vs. noncontinuous state of the stepper.
        ///   - autorepeat: The automatic vs. nonautomatic repeat state of the stepper.
        ///   - wraps: The wrap vs. no-wrap state of the stepper.
        public init(
            value: Int,
            minimumValue: Int,
            maximumValue: Int,
            stepValue: Int = 1,
            isContinuous: Bool = true,
            autorepeat: Bool = true,
            wraps: Bool = false
        ) {
            self.value        = Double(value)
            self.minimumValue = Double(minimumValue)
            self.maximumValue = Double(maximumValue)
            self.stepValue    = Double(stepValue)
            self.isContinuous = isContinuous
            self.autorepeat   = autorepeat
            self.wraps        = wraps
        }
        
        public static let defaultOptions = UIStepper.Options(
            value: 0,
            minimumValue: 0,
            maximumValue: 100
        )
    }
}
