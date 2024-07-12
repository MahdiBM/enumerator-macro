import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument
    case allArgumentsMustBeStringLiterals(violation: String)
    case renderedSyntaxContainsErrors(String)
    case couldNotFindLocationOfNode(syntax: String)
    case mustacheTemplateError(message: String)
    case internalError(String)

    var description: String {
        switch self {
        case .isNotEnum:
            "Only enums are supported"
        case .macroDeclarationHasNoArguments:
            "The macro declaration needs to have at least 1 StringLiteral argument"
        case .unacceptableArguments:
            "The arguments passed to the macro were unacceptable"
        case .expectedAtLeastOneArgument:
            "At least one argument of type StaticString is required"
        case let .allArgumentsMustBeStringLiterals(violation):
            "All arguments must be string literals, but found: \(violation)"
        case let .renderedSyntaxContainsErrors(syntax):
            "Rendered syntax contains errors:\n\(syntax)"
        case let .couldNotFindLocationOfNode(syntax):
            "Could not find location of node for syntax:\n\(syntax)"
        case let .mustacheTemplateError(message):
            "Error while rendering the template: \(message)"
        case let .internalError(message):
            "An internal error occurred. Please file a bug report at https://github.com/mahdibm/enumerator-macro. Error:\n\(message)"
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
