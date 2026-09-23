// English: Semantic symbols keep feature code independent from Apple's raw symbol naming.
// Español: Los símbolos semánticos desacoplan el código de funciones de los nombres raw de Apple.
// 中文：语义符号让功能代码不依赖 Apple 的原始符号名称。

public enum PTSymbols {
    public enum Actions {
        public static let close = PTSymbol.xmark
        public static let delete = PTSymbol.trash
        public static let edit = PTSymbol.pencil
        public static let add = PTSymbol.plus
        public static let search = PTSymbol.magnifyingglass
    }

    public enum Navigation {
        public static let back = PTSymbol.chevronLeft
        public static let forward = PTSymbol.chevronRight
        public static let menu = PTSymbol.ellipsis
    }

    public enum Media {
        public static let play = PTSymbol.play
        public static let pause = PTSymbol.pause
        public static let video = PTSymbol.video
        public static let photo = PTSymbol.photo
    }

    public enum Status {
        public static let warning = PTSymbol.exclamationmarkTriangle
        public static let success = PTSymbol.checkmarkCircle
        public static let error = PTSymbol.xmarkCircle
    }
}
