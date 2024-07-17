import SwiftSyntax

struct EParameter {
    let name: EOptional<EString>
    let type: EString
    let isOptional: EBool

    init(parameter: EnumCaseParameterSyntax) {
        let parameterName = parameter.secondName ?? parameter.firstName
        self.name = .init(parameterName.map { .init($0.trimmedDescription) })
        self.type = .init(parameter.type.trimmedDescription)
        self.isOptional = EBool(parameter.type.isOptional)
    }

    init(name: EString?, type: EString, isOptional: Bool = false) {
        self.name = .init(name)
        self.type = type
        self.isOptional = EBool(isOptional)
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
