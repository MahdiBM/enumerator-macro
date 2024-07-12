import SwiftDiagnostics
import SwiftSyntax
import Mustache

struct EnumCase {
    let name: EString
    let parameters: EParameters

    init(from element: EnumCaseElementSyntax) throws {
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(underlying: parameters.map { parameter in
            EParameter(
                name: (parameter.secondName ?? parameter.firstName)?.trimmedDescription,
                type: parameter.type.trimmedDescription
            )
        })
    }
}
