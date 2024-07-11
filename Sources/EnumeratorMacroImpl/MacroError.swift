import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument
    case allArgumentsMustBeStringLiterals(violation: String)
    case renderedSyntaxContainsErrors(String)
    case customNameIsEnteredForMacroButCannotFindWorkingDirectory(name: String)
    case customNameIsEnteredForMacroButFileDoesNotExist(name: String, path: String)

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
            "A rendered syntax contains errors:\n\(syntax)"
        case let .customNameIsEnteredForMacroButCannotFindWorkingDirectory(name):
            "A custom name '\(name)' is entered for macro which indicates to look for a predefined mustache template, but the macro can't find your working directory"
        case let .customNameIsEnteredForMacroButFileDoesNotExist(name, path):
            "A custom name '\(name)' is entered for macro which indicates to look for a predefined mustache template, but no file seems to exist at path '\(path)'"
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
