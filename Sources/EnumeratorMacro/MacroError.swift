import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments

    var description: String {
        switch self {
        case .isNotEnum:
            "Only enums are supported."
        case .macroDeclarationHasNoArguments:
            "The macro declaration needs to have at least 1 StringLiteral argument."
        }
    }
}

extension MacroError: DiagnosticMessage {
    var message: String {
        self.description
    }

    var diagnosticID: MessageID {
        .init(domain: "EnumeratorMacro.MacroError", id: self.description)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
