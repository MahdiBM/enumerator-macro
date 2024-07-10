func convertToCustomTypesIfPossible(_ value: Any) -> Any {
    switch value {
    case let string as any StringProtocol:
        return MString(string.description)
    case let array as Array<EnumCase.Parameter>:
        return EnumCase.Parameters(underlying: array)
    case let seq as any Sequence:
        return MArray<Any>(underlying: seq.map { $0 })
        /// TODO: Handle arrays of optionals
    default:
        return value
    }
}
