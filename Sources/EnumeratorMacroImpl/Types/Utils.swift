func convertToCustomTypesIfPossible(_ value: Any) -> Any {
    switch value {
    case let string as any StringProtocol:
        return EString(string.description)
    case let array as Array<EParameter>:
        return EParameters(underlying: array)
    case let seq as any Sequence:
        return EArray<Any>(
            underlying: convertHomogeneousArrayToCustomTypes(seq.map { $0 })
        )
        /// TODO: Handle arrays of optionals
    default:
        return value
    }
}

private func convertHomogeneousArrayToCustomTypes(_ values: [Any]) -> [Any] {
    guard let first = values.first else {
        return values
    }
    switch first {
    case is any StringProtocol:
        return values.map {
            let string = $0 as! (any StringProtocol)
            return EString(string.description)
        }
    case is Array<EParameter>:
        return values.map {
            let array = $0 as! Array<EParameter>
            return EParameters(underlying: array)
        }
    case is any Sequence:
        return values.map {
            let seq = $0 as! (any Sequence)
            return EArray<Any>(
                underlying: convertHomogeneousArrayToCustomTypes(seq.map { $0 })
            )
        }
        /// TODO: Handle arrays of optionals
    default:
        return values
    }
}
