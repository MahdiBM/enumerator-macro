import Mustache

struct EBool {
    var underlying: Bool

    init(_ underlying: Bool) {
        self.underlying = underlying
    }
}

extension EBool: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EBool: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "Bool"
    }
}

extension EBool: CustomReflectable {
    var customMirror: Mirror {
        self.underlying.customMirror
    }
}

extension EBool: Comparable {
    static func < (lhs: EBool, rhs: EBool) -> Bool {
        !lhs.underlying && rhs.underlying
    }
}
