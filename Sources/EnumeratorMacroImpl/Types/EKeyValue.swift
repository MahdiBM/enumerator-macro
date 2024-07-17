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
            return Value(base: self)
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

extension EKeyValue {
    struct Value {
        fileprivate let base: EKeyValue?

        init(base: EKeyValue?) {
            self.base = base
        }
    }
}

extension [EKeyValue] {
    func first(named name: EString) -> EKeyValue.Value {
        EKeyValue.Value(
            base: self.first(where: { $0.key == name })
        )
    }
}

extension EKeyValue.Value: CustomStringConvertible {
    var description: String {
        String(describing: self.base?.value)
    }
}

extension EKeyValue.Value: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "KeyValue<String, String>.Value"
    }
}

extension EKeyValue.Value: Comparable {
    static func < (lhs: EKeyValue.Value, rhs: EKeyValue.Value) -> Bool {
        EOptional(lhs.base?.value) < EOptional(rhs.base?.value)
    }

    static func == (lhs: EKeyValue.Value, rhs: EKeyValue.Value) -> Bool {
        lhs.base?.value == rhs.base?.value
    }
}

extension EKeyValue.Value: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch self.base {
        case .none:
            switch name {
            case "exists":
                return false
            case "empty":
                return true
            case "bool":
                return false
            default:
                RenderingContext.current.addOrReplaceDiagnostic(
                    .invalidTransform(
                        transform: name,
                        normalizedTypeName: Self.normalizedTypeName
                    )
                )
                return nil
            }
        case let .some(keyValue):
            let value = keyValue.value
            switch name {
            case "exists":
                return true
            case "empty":
                return value.isEmpty
            case "bool":
                return Bool(value)
            default:
                return value.transform(name)
            }
        }
    }
}
