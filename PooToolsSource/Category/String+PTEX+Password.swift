//
//  String+PTEX+Password.swift
//  PooTools
//
//  English: Password-strength helpers are isolated from the general String extensions.
//  Español: Los ayudantes de fortaleza de contraseña están aislados de las extensiones generales de String.
//  中文：密码强度辅助方法与通用 String 扩展职责分离。
//

import Foundation

// English: Keep the public password API unchanged while isolating its private scoring helpers.
// Español: Mantén sin cambios la API pública de contraseñas y aísla sus ayudantes privados de puntuación.
// 中文：保持公开密码 API 不变，同时隔离私有评分辅助方法。
public extension String {
    // English: Classify each character once so the score remains deterministic and inexpensive.
    // Español: Clasifica cada carácter una vez para que la puntuación sea determinista y económica.
    // 中文：每个字符只分类一次，保证评分稳定且开销可控。
    private enum CharType { case number, lower, upper, other }

    private func charType(_ character: Character) -> CharType {
        if character.isNumber { return .number }
        if character.isLowercase { return .lower }
        if character.isUppercase { return .upper }
        return .other
    }

    private func isNull() -> Bool { isEmpty }

    private func isCharEqual() -> Bool {
        guard let first = first else { return true }
        return !contains { $0 != first }
    }

    private func isNumeric() -> Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }

    // English: Return the existing password-strength categories for source compatibility.
    // Español: Devuelve las categorías existentes de fortaleza para mantener la compatibilidad del código fuente.
    // 中文：返回现有密码强度分类，保持源码兼容性。
    func passwordLevel(commonUsers: [String] = []) -> PStrengthLevel {
        let level = checkPasswordStrength(commonUsers: commonUsers)
        switch level {
        case 1...3: return .Easy
        case 4...6: return .Midium
        case 7...9: return .Strong
        case 10...12: return .Very_Strong
        default: return .Extremely_Strong
        }
    }

    private func checkPasswordStrength(commonUsers: [String]) -> Int {
        if isNull() || isCharEqual() { return 0 }

        var num = 0, lower = 0, upper = 0, other = 0
        for character in self {
            switch charType(character) {
            case .number: num += 1
            case .lower: lower += 1
            case .upper: upper += 1
            case .other: other += 1
            }
        }

        let length = count
        var level = 0

        // English: Award points for character classes and minimum lengths.
        // Español: Asigna puntos por clases de caracteres y longitudes mínimas.
        // 中文：根据字符类型和最小长度增加基础分数。
        if num > 0 { level += 1 }
        if lower > 0 { level += 1 }
        if upper > 0 && length > 4 { level += 1 }
        if other > 0 && length > 6 { level += 1 }

        let types = [num, lower, upper, other].filter { $0 > 0 }.count
        if types >= 2 { level += 1 }
        if types >= 3 && length > 6 { level += 1 }
        if types == 4 && length > 8 { level += 1 }

        if length > 12 { level += 1 }
        if length >= 16 { level += 1 }

        // English: Penalize repeated, common, keyboard, and numeric-date patterns.
        // Español: Penaliza patrones repetidos, comunes, de teclado y de fecha numérica.
        // 中文：对重复、常见、键盘序列和数字日期模式进行扣分。
        if isRepeatedPattern(length: length) { level -= 1 }
        if isCommonPassword(commonUsers) { level -= 1 }
        if isKeyboardPattern() { level -= 1 }
        if isNumericDatePattern(length: length) { level -= 1 }

        return max(level, 0)
    }

    // English: Detect simple two-part and three-part repetitions without changing the original scoring rules.
    // Español: Detecta repeticiones simples de dos y tres partes sin cambiar las reglas de puntuación originales.
    // 中文：检测简单的两段和三段重复，不改变原有评分规则。
    private func isRepeatedPattern(length: Int) -> Bool {
        if length % 2 == 0 {
            let middle = length / 2
            let part1 = String(prefix(middle))
            let part2 = String(suffix(middle))
            if part1 == part2 { return true }
            if part1.isCharEqual() && part2.isCharEqual() { return true }
        }
        if length % 3 == 0 {
            let third = length / 3
            let part1 = prefix(third)
            let part2 = self[index(startIndex, offsetBy: third)..<index(startIndex, offsetBy: 2 * third)]
            let part3 = suffix(third)
            if part1 == part2 && part2 == part3 { return true }
        }
        return false
    }

    private func isCommonPassword(_ list: [String]) -> Bool {
        list.contains(self) || list.contains { $0.contains(self) }
    }

    private func isKeyboardPattern() -> Bool {
        let lowercasedValue = lowercased()
        return ["qwertyuiop", "asdfghjkl", "zxcvbnm"].contains { lowercasedValue.contains($0) }
    }

    private func isNumericDatePattern(length: Int) -> Bool {
        guard isNumeric(), length >= 6 else { return false }
        var year = 0
        if length == 6 || length == 8 {
            year = Int(String(prefix(length - 4))) ?? 0
        }
        let month = Int(self[index(startIndex, offsetBy: length - 4)..<index(startIndex, offsetBy: length - 2)]) ?? 0
        let day = Int(suffix(2)) ?? 0
        return (1950..<2050).contains(year) && (1...12).contains(month) && (1...31).contains(day)
    }
}
