import SwiftDiagnostics
import SwiftSyntax
import Mustache

struct ECase {
    let index: Int
    let name: EString
    let parameters: EParameters
    let comments: EArray<EString>

    init(index: Int, from element: EnumCaseElementSyntax) throws {
        self.index = index
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(
            underlying: parameters.map(EParameter.init(parameter:))
        )
        let keyValueParts = element.trailingTrivia
            .description
            .replacingOccurrences(of: "///", with: "") /// remove comment signs
            .replacingOccurrences(of: "//", with: "") /// remove comment signs
            .split(separator: ";") /// separator of parameters

        self.comments = .init(underlying: keyValueParts.map(EString.init))
    }
}
