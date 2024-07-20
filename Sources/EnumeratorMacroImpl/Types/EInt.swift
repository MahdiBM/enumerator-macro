import Mustache

struct EInt {
    static var normalizedTypeName: String {
        "Int"
    }

    var underlying: Int

    init(_ underlying: Int) {
        self.underlying = underlying
    }
}

extension EInt: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EInt: CustomReflectable {
    var customMirror: Mirror {
        self.underlying.customMirror
    }
}

extension EInt: Comparable {
    static func < (lhs: EInt, rhs: EInt) -> Bool {
        lhs.underlying < rhs.underlying
    }
}

extension EInt: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "equalsZero":
            return self.underlying == 0
        case "plusOne":
            return EInt(self.underlying + 1)
        case "minusOne":
            return EInt(self.underlying - 1)
        case "isEven":
            return (self.underlying & 1) == 0
        case "isOdd":
            return (self.underlying & 1) == 1
        default:
            RenderingContext.current.addOrReplaceDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}
