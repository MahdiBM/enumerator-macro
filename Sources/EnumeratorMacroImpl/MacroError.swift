import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument
    case allArgumentsMustBeStringLiterals(violation: String)
    case renderedSyntaxesContainsErrors([String])

    var description: String {
        switch self {
        case .isNotEnum:
            return "Only enums are supported"
        case .macroDeclarationHasNoArguments:
            return "The macro declaration needs to have at least 1 StringLiteral argument"
        case .unacceptableArguments:
            return "The arguments passed to the macro were unacceptable"
        case .expectedAtLeastOneArgument:
            return "At least one argument of type StaticString is required"
        case let .allArgumentsMustBeStringLiterals(violation):
            return "All arguments must be string literals, but found: \(violation)"
        case let .renderedSyntaxesContainsErrors(syntaxes):
            let syntaxes = syntaxes.joined(separator: "\n\(String(repeating: "-", count: 20))\n")
            return "Some rendered syntaxes contain errors:\n\(syntaxes)"
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
