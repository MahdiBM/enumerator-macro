
protocol WithNormalizedTypeName {
    static var normalizedTypeName: String { get }
}

func bestEffortTypeName<T>(_ type: T.Type = T.self) -> String {
    switch type {
    case let customType as any WithNormalizedTypeName.Type:
        customType.normalizedTypeName
    default:
        Swift._typeName(type, qualified: false)
    }
}
