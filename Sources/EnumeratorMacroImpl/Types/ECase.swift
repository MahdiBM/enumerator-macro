import SwiftDiagnostics
import SwiftSyntax
import Mustache

struct ECase {
    let name: EString
    let parameters: EParameters

    init(from element: EnumCaseElementSyntax) throws {
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(
            underlying: parameters.map(EParameter.init(parameter:))
        )
    }
}