import SwiftDiagnostics
import SwiftSyntax
import Foundation
import Mustache

struct ECase {
    let index: EInt
    let name: EString
    let parameters: EParameters
    let comments: EArray<EString>

    init(index: Int, from element: EnumCaseElementSyntax) throws {
        self.index = .init(index)
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(
            underlying: parameters.enumerated().map { idx, parameter in
                EParameter(
                    index: idx,
                    parameter: parameter
                )
            }
        )
        let keyValueParts = element.trailingTrivia
            .description
            .replacingOccurrences(of: "///", with: "") /// remove comment signs
            .replacingOccurrences(of: "//", with: "") /// remove comment signs
            .split(separator: ";") /// separator of parameters
            .map {
                $0.trimmingCharacters(in: .whitespaces)
            }

        self.comments = .init(underlying: keyValueParts.map(EString.init(stringLiteral:)))
    }

    init(
        index: Int,
        name: EString,
        parameters: EParameters,
        comments: [EString]
    ) {
        self.index = EInt(index)
        self.name = name
        self.parameters = parameters
        self.comments = .init(underlying: comments)
    }
}

extension ECase: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "Case"
    }
}

extension ECase: Comparable {
    static func < (lhs: ECase, rhs: ECase) -> Bool {
        lhs.name < rhs.name
    }

    static func == (lhs: ECase, rhs: ECase) -> Bool {
        lhs.name == rhs.name
    }
}
