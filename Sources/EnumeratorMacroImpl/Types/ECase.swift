import SwiftDiagnostics
import SwiftSyntax
import Mustache

struct ECase {
    let index: Int
    let name: EString
    let parameters: EParameters

    init(index: Int, from element: EnumCaseElementSyntax) throws {
        self.index = index
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(
            underlying: parameters.map(EParameter.init(parameter:))
        )
    }
}
