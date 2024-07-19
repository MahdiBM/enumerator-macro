import SwiftDiagnostics
import SwiftSyntax
import Foundation
import Mustache

struct ECase {
    let node: EnumCaseElementSyntax
    let name: EString
    let parameters: EParameters
    let comments: EComments
    let index: EInt
    let isFirst: Bool
    let isLast: Bool

    init(
        from element: EnumCaseElementSyntax,
        index: Int,
        isFirst: Bool,
        isLast: Bool
    ) throws {
        self.node = element
        self.index = EInt(index)
        self.isFirst = isFirst
        self.isLast = isLast
        
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        let lastIdx = parameters.count - 1
        self.parameters = .init(
            underlying: parameters.enumerated().map { idx, parameter in
                EParameter(
                    from: parameter,
                    index: idx,
                    isFirst: idx == 0,
                    isLast: idx == lastIdx
                )
            }
        )

        let keyValues: [EKeyValue] = element.trailingTrivia
            .description
            .replacingOccurrences(of: "///", with: "") /// remove comment signs
            .replacingOccurrences(of: "//", with: "") /// remove comment signs
            .split(separator: ";") /// separator of parameters
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap {
                EKeyValue(from: $0)
            }
        self.comments = .init(underlying: keyValues)
    }

    init(
        node: EnumCaseElementSyntax,
        name: EString,
        parameters: EParameters,
        comments: [EKeyValue],
        index: Int,
        isFirst: Bool,
        isLast: Bool
    ) {
        self.node = node
        self.name = name
        self.parameters = parameters
        self.comments = .init(underlying: comments)
        self.index = EInt(index)
        self.isFirst = isFirst
        self.isLast = isLast
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
