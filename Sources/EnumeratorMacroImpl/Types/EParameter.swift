import SwiftSyntax

struct EParameter {
    let name: EString?
    let type: EString
    let isOptional: Bool

    init(parameter: EnumCaseParameterSyntax) {
        let parameterName = parameter.secondName ?? parameter.firstName
        self.name = parameterName.map { .init($0.trimmedDescription) }
        self.type = .init(parameter.type.trimmedDescription)
        self.isOptional = parameter.type.isOptional
    }

    init(name: EString?, type: EString, isOptional: Bool = false) {
        self.name = name
        self.type = type
        self.isOptional = isOptional
    }
}

extension EParameter: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "Parameter"
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
