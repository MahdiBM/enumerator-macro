func convertToCustomTypesIfPossible(_ value: Any) -> Any {
    switch value {
    case let `optional` as OptionalProtocol:
        return `optional`.asConvertedOptionalAny()
    case let string as any StringProtocol:
        return EString(string.description)
    case let seq as any Sequence<EParameter>:
        return EParameters(underlying: seq.map { $0 })
    case let seq as any Sequence:
        switch convertHomogeneousArrayToCustomTypes(seq.map { $0 }) {
        case let .anys(values):
            return EArray<Any>(underlying: values)
        case let .optionalAnys(values):
            return EOptionalsArray<Any>(underlying: values)
        }
    default:
        return value
    }
}

enum Elements {
    case anys([Any])
    case optionalAnys([EOptional<Any>])
}

private func convertHomogeneousArrayToCustomTypes(_ values: [Any]) -> Elements {
    guard let first = values.first else {
        return .anys(values)
    }
    switch first {
    case is any OptionalProtocol:
        return .optionalAnys(values.map {
            let optionalProtocol = $0 as! (any OptionalProtocol)
            let optional = optionalProtocol.asConvertedOptionalAny()
            return optional
        })
    case is any StringProtocol:
        return .anys(values.map {
            let string = $0 as! (any StringProtocol)
            return EString(string.description)
        })
    case is any Sequence<EParameter>:
        return .anys(values.map {
            let seq = $0 as! any Sequence<EParameter>
            return EParameters(underlying: seq.map { $0 })
        })
    case is any Sequence:
        return .anys(values.map {
            let seq = $0 as! (any Sequence)
            switch convertHomogeneousArrayToCustomTypes(seq.map { $0 }) {
            case let .anys(values):
                return EArray<Any>(underlying: values)
            case let .optionalAnys(values):
                return EOptionalsArray<Any>(underlying: values)
            }
        })
    default:
        return .anys(values)
    }
}

private protocol OptionalProtocol {
    func asConvertedOptionalAny() -> EOptional<Any>
}

extension Optional: OptionalProtocol {
    func asConvertedOptionalAny() -> EOptional<Any> {
        EOptional(self).map {
            convertToCustomTypesIfPossible($0)
        }
    }
}

extension EOptional: OptionalProtocol {
    func asConvertedOptionalAny() -> EOptional<Any> {
        self.map {
            convertToCustomTypesIfPossible($0)
        }
    }
}
