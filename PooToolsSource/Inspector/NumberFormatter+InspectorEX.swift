//
//  NumberFormatter+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

public extension NumberFormatter {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        apply(numberFormatterOptions: options)
    }
}

public extension NumberFormatter {
    func apply(numberFormatterOptions options: Option...) {
        apply(numberFormatterOptions: options)
    }
    
    func apply(numberFormatterOptions: Options) {
        numberFormatterOptions.forEach { option in
            switch option {
            case let .formattingContext(formattingContext):
                self.formattingContext = formattingContext
                
            case let .numberStyle(numberStyle):
                self.numberStyle = numberStyle
                
            case let .locale(locale):
                self.locale = locale
                
            case let .generatesDecimalNumbers(generatesDecimalNumbers):
                self.generatesDecimalNumbers = generatesDecimalNumbers
                
            case let .formatterBehavior(formatterBehavior):
                self.formatterBehavior = formatterBehavior
                
            case let .negativeFormat(negativeFormat):
                self.negativeFormat = negativeFormat
                
            case let .textAttributesForNegativeValues(textAttributesForNegativeValues):
                self.textAttributesForNegativeValues = textAttributesForNegativeValues
                
            case let .positiveFormat(positiveFormat):
                self.positiveFormat = positiveFormat
                
            case let .textAttributesForPositiveValues(textAttributesForPositiveValues):
                self.textAttributesForPositiveValues = textAttributesForPositiveValues
                
            case let .allowsFloats(allowsFloats):
                self.allowsFloats = allowsFloats
                
            case let .decimalSeparator(decimalSeparator):
                self.decimalSeparator = decimalSeparator
                
            case let .alwaysShowsDecimalSeparator(alwaysShowsDecimalSeparator):
                self.alwaysShowsDecimalSeparator = alwaysShowsDecimalSeparator
                
            case let .currencyDecimalSeparator(currencyDecimalSeparator):
                self.currencyDecimalSeparator = currencyDecimalSeparator
                
            case let .usesGroupingSeparator(usesGroupingSeparator):
                self.usesGroupingSeparator = usesGroupingSeparator
                
            case let .groupingSeparator(groupingSeparator):
                self.groupingSeparator = groupingSeparator
                
            case let .zeroSymbol(zeroSymbol):
                self.zeroSymbol = zeroSymbol
                
            case let .textAttributesForZero(textAttributesForZero):
                self.textAttributesForZero = textAttributesForZero
                
            case let .nilSymbol(nilSymbol):
                self.nilSymbol = nilSymbol
                
            case let .textAttributesForNil(textAttributesForNil):
                self.textAttributesForNil = textAttributesForNil
                
            case let .notANumberSymbol(notANumberSymbol):
                self.notANumberSymbol = notANumberSymbol
                
            case let .textAttributesForNotANumber(textAttributesForNotANumber):
                self.textAttributesForNotANumber = textAttributesForNotANumber
                
            case let .positiveInfinitySymbol(positiveInfinitySymbol):
                self.positiveInfinitySymbol = positiveInfinitySymbol
                
            case let .textAttributesForPositiveInfinity(textAttributesForPositiveInfinity):
                self.textAttributesForPositiveInfinity = textAttributesForPositiveInfinity
                
            case let .negativeInfinitySymbol(negativeInfinitySymbol):
                self.negativeInfinitySymbol = negativeInfinitySymbol
                
            case let .textAttributesForNegativeInfinity(textAttributesForNegativeInfinity):
                self.textAttributesForNegativeInfinity = textAttributesForNegativeInfinity
                
            case let .positivePrefix(positivePrefix):
                self.positivePrefix = positivePrefix
                
            case let .positiveSuffix(positiveSuffix):
                self.positiveSuffix = positiveSuffix
                
            case let .negativePrefix(negativePrefix):
                self.negativePrefix = negativePrefix
                
            case let .negativeSuffix(negativeSuffix):
                self.negativeSuffix = negativeSuffix
                
            case let .currencyCode(currencyCode):
                self.currencyCode = currencyCode
                
            case let .currencySymbol(currencySymbol):
                self.currencySymbol = currencySymbol
                
            case let .internationalCurrencySymbol(internationalCurrencySymbol):
                self.internationalCurrencySymbol = internationalCurrencySymbol
                
            case let .percentSymbol(percentSymbol):
                self.percentSymbol = percentSymbol
                
            case let .perMillSymbol(perMillSymbol):
                self.perMillSymbol = perMillSymbol
                
            case let .minusSign(minusSign):
                self.minusSign = minusSign
                
            case let .plusSign(plusSign):
                self.plusSign = plusSign
                
            case let .exponentSymbol(exponentSymbol):
                self.exponentSymbol = exponentSymbol
                
            case let .groupingSize(groupingSize):
                self.groupingSize = groupingSize
                
            case let .secondaryGroupingSize(secondaryGroupingSize):
                self.secondaryGroupingSize = secondaryGroupingSize
                
            case let .multiplier(multiplier):
                self.multiplier = multiplier
                
            case let .formatWidth(formatWidth):
                self.formatWidth = formatWidth
                
            case let .paddingCharacter(paddingCharacter):
                self.paddingCharacter = paddingCharacter
                
            case let .paddingPosition(paddingPosition):
                self.paddingPosition = paddingPosition
                
            case let .roundingMode(roundingMode):
                self.roundingMode = roundingMode
                
            case let .roundingIncrement(roundingIncrement):
                self.roundingIncrement = roundingIncrement
                
            case let .minimumIntegerDigits(minimumIntegerDigits):
                self.minimumIntegerDigits = minimumIntegerDigits
                
            case let .maximumIntegerDigits(maximumIntegerDigits):
                self.maximumIntegerDigits = maximumIntegerDigits
                
            case let .minimumFractionDigits(minimumFractionDigits):
                self.minimumFractionDigits = minimumFractionDigits
                
            case let .maximumFractionDigits(maximumFractionDigits):
                self.maximumFractionDigits = maximumFractionDigits
                
            case let .minimum(minimum):
                self.minimum = minimum
                
            case let .maximum(maximum):
                self.maximum = maximum
                
            case let .currencyGroupingSeparator(currencyGroupingSeparator):
                self.currencyGroupingSeparator = currencyGroupingSeparator
                
            case let .isLenient(isLenient):
                self.isLenient = isLenient
                
            case let .usesSignificantDigits(usesSignificantDigits):
                self.usesSignificantDigits = usesSignificantDigits
                
            case let .minimumSignificantDigits(minimumSignificantDigits):
                self.minimumSignificantDigits = minimumSignificantDigits
                
            case let .maximumSignificantDigits(maximumSignificantDigits):
                self.maximumSignificantDigits = maximumSignificantDigits
                
            case let .isPartialStringValidationEnabled(isPartialStringValidationEnabled):
                self.isPartialStringValidationEnabled = isPartialStringValidationEnabled
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The capitalization formatting context used when formatting a number.
        case formattingContext(Formatter.Context)
        
        /// The number style used by the receiver.
        case numberStyle(Style)
        
        // The locale of the receiver.
        case locale(Locale)
        
        /// Determines whether the receiver creates instances of NSDecimalNumber when it converts strings to number objects.
        case generatesDecimalNumbers(Bool)
        
        /// The formatter behavior of the receiver.
        case formatterBehavior(NumberFormatter.Behavior)
        
        /// The format the receiver uses to display negative values.
        case negativeFormat(String)
        
        /// The text attributes to be used in displaying negative values.
        case textAttributesForNegativeValues([String : Any]?)
        
        /// The format the receiver uses to display positive values.
        case positiveFormat(String)
        
        /// The text attributes to be used in displaying positive values.
        case textAttributesForPositiveValues([String : Any]?)
        
        /// Determines whether the receiver allows as input floating-point values (that is, values that include the period character [.]).
        case allowsFloats(Bool)
        
        /// The character the receiver uses as a decimal separator.
        case decimalSeparator(String)
        
        /// Determines whether the receiver always shows the decimal separator, even for integer numbers.
        case alwaysShowsDecimalSeparator(Bool)
        
        /// The string used by the receiver as a currency decimal separator.
        case currencyDecimalSeparator(String)
        
        /// Determines whether the receiver displays the group separator.
        case usesGroupingSeparator(Bool)
        
        /// The string used by the receiver for a grouping separator.
        case groupingSeparator(String)
        
        /// The string used to represent a zero value.
        case zeroSymbol(String?)
        
        /// The text attributes used to display a zero value.
        case textAttributesForZero([String : Any]?)
        
        /// The string used to represent a nil value.
        case nilSymbol(String)
        
        /// The text attributes used to display the nil symbol.
        case textAttributesForNil([String : Any]?)
        
        /// The string used to represent a NaN (“not a number”) value.
        case notANumberSymbol(String)
        
        /// The text attributes used to display the NaN (“not a number”) string.
        case textAttributesForNotANumber([String : Any]?)
        
        /// The string used to represent a positive infinity symbol.
        case positiveInfinitySymbol(String)
        
        /// The text attributes used to display the positive infinity symbol.
        case textAttributesForPositiveInfinity([String : Any]?)
        
        /// The string used to represent a negative infinity symbol.
        case negativeInfinitySymbol(String)
        
        /// The text attributes used to display the negative infinity symbol.
        case textAttributesForNegativeInfinity([String : Any]?)
        
        /// The string the receiver uses as the prefix for positive values.
        case positivePrefix(String)
        
        /// The string the receiver uses as the suffix for positive values.
        case positiveSuffix(String)
        
        /// The string the receiver uses as a suffix for negative values.
        case negativePrefix(String)
        
        /// The string the receiver uses as a suffix for negative values.
        case negativeSuffix(String)
        
        /// The receiver’s currency code.
        case currencyCode(String)
        
        /// The string used by the receiver as a local currency symbol.
        case currencySymbol(String)
        
        /// The international currency symbol used by the receiver.
        case internationalCurrencySymbol(String)
        
        /// The string used to represent a percent symbol.
        case percentSymbol(String)
        
        /// The string used to represent a per-mill (per-thousand) symbol.
        case perMillSymbol(String)
        
        /// The string used to represent a minus sign.
        case minusSign(String)
        
        /// The string used to represent a plus sign.
        case plusSign(String)
        
        /// The string used to represent an exponent symbol.
        case exponentSymbol(String)
        
        /// The grouping size of the receiver.
        case groupingSize(Int)
        
        /// The secondary grouping size of the receiver.
        case secondaryGroupingSize(Int)
        
        /// The multiplier of the receiver.
        case multiplier(NSNumber?)
        
        /// The format width used by the receiver.
        case formatWidth(Int)
        
        /// The string that the receiver uses to pad numbers in the formatted string representation.
        case paddingCharacter(String)
        
        /// The padding position used by the receiver.
        case paddingPosition(PadPosition)
        
        /// The rounding mode used by the receiver.
        case roundingMode(RoundingMode)
        
        /// The rounding increment used by the receiver.
        case roundingIncrement(NSNumber)
        
        /// The minimum number of digits before the decimal separator.
        case minimumIntegerDigits(Int)
        
        /// The maximum number of digits before the decimal separator.
        case maximumIntegerDigits(Int)
        
        /// The minimum number of digits after the decimal separator.
        case minimumFractionDigits(Int)
        
        /// The maximum number of digits after the decimal separator.
        case maximumFractionDigits(Int)
        
        /// The lowest number allowed as input by the receiver.
        case minimum(NSNumber?)
        
        /// The highest number allowed as input by the receiver.
        case maximum(NSNumber?)
        
        /// The currency grouping separator for the receiver.
        case currencyGroupingSeparator(String)
        
        /// Determines whether the receiver will use heuristics to guess at the number which is intended by a string.
        case isLenient(Bool)
        
        /// A Boolean value indicating whether the formatter uses minimum and maximum significant digits when formatting numbers.
        case usesSignificantDigits(Bool)
        
        /// The minimum number of significant digits for the number formatter.
        case minimumSignificantDigits(Int)
        
        /// The maximum number of significant digits for the number formatter.
        case maximumSignificantDigits(Int)
        
        /// Determines whether partial string validation is enabled for the receiver.
        case isPartialStringValidationEnabled(Bool)
    }
}
