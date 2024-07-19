import SwiftSyntax

struct EParameter {
    let index: EInt
    let name: EString
    let type: EString
    let isOptional: Bool
    let isFirst: Bool
    let isLast: Bool

    init(
        from parameter: EnumCaseParameterSyntax,
        index: Int,
        isFirst: Bool,
        isLast: Bool
    ) {
        self.index = EInt(index)
        self.isFirst = isFirst
        self.isLast = isLast

        let parameterName = (parameter.secondName ?? parameter.firstName)?.trimmedDescription
        if let parameterName,
           !parameterName.isEmpty {
            self.name = .init(parameterName)
        } else {
            self.name = .init("param\(index + 1)")
        }
        self.type = .init(parameter.type.trimmedDescription)
        self.isOptional = parameter.type.isOptional
    }

    init(
        name: EString,
        type: EString,
        isOptional: Bool,
        index: Int,
        isFirst: Bool,
        isLast: Bool
    ) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.index = EInt(index)
        self.isFirst = isFirst
        self.isLast = isLast
    }
}

extension EParameter: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "Parameter"
    }
}

extension EParameter: Comparable {
    static func < (lhs: EParameter, rhs: EParameter) -> Bool {
        lhs.name < rhs.name
    }

    static func == (lhs: EParameter, rhs: EParameter) -> Bool {
        lhs.name == rhs.name
    }
}

private extension TypeSyntax {
    var isOptional: Bool {
        switch self.kind {
        case .optionalType, .implicitlyUnwrappedOptionalType:
            return true
        case .identifierType:
            if let type = self.as(IdentifierTypeSyntax.self),
               let genericArgumentClause = type.genericArgumentClause,
               !genericArgumentClause.arguments.isEmpty {
                let arguments = genericArgumentClause.arguments
                switch (arguments.count, type.name.tokenKind) {
                case (1, .identifier("Optional")):
                    return true
                default:
                    return false
                }
            }
            return false
        default: 
            return false
        }
    }
}
