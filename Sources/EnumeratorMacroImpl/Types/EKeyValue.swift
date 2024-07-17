import Mustache

struct EKeyValue {
    let key: EString
    let value: EString

    init(key: EString, value: EString) {
        self.key = key
        self.value = value
    }
}

extension EKeyValue: CustomStringConvertible {
    var description: String {
        "(key: \(key), value: \(value))"
    }
}

extension EKeyValue: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "KeyValue<String, String>"
    }
}

extension EKeyValue: Comparable {
    static func < (lhs: EKeyValue, rhs: EKeyValue) -> Bool {
        lhs.key < rhs.key
    }

    static func == (lhs: EKeyValue, rhs: EKeyValue) -> Bool {
        lhs.key == rhs.key
    }
}

extension EKeyValue: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "key":
            return self.key
        case "value":
            return self.value
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
