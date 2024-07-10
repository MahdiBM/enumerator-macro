func convertToCustomTypesIfPossible(_ value: Any) -> Any {
    switch value {
    case let string as any StringProtocol:
        return EString(string.description)
    case let array as Array<EParameter>:
        return EParameters(underlying: array)
    case let seq as any Sequence:
        return EArray<Any>(underlying: seq.map { $0 })
        /// TODO: Handle arrays of optionals
    default:
        return value
    }
}
