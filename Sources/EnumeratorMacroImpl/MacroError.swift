import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument
    case invalidArgument
    case expectedNonInterpolatedStringLiteral
    case renderedSyntaxContainsErrors(String)
    case couldNotFindLocationOfNode(syntax: String)
    case mustacheTemplateError(message: String)
    case internalError(String)
    case invalidTransform(transform: String, normalizedTypeName: String)
    case commentKeyNotAllowed(key: String)
    case declaredHere(name: String)

    var caseName: String {
        switch self {
        case .isNotEnum:
            "isNotEnum"
        case .macroDeclarationHasNoArguments:
            "macroDeclarationHasNoArguments"
        case .unacceptableArguments:
            "unacceptableArguments"
        case .expectedAtLeastOneArgument:
            "expectedAtLeastOneArgument"
        case .invalidArgument:
            "invalidArgument"
        case .expectedNonInterpolatedStringLiteral:
            "expectedNonInterpolatedStringLiteral"
        case .renderedSyntaxContainsErrors:
            "renderedSyntaxContainsErrors"
        case .couldNotFindLocationOfNode:
            "couldNotFindLocationOfNode"
        case .mustacheTemplateError:
            "mustacheTemplateError"
        case .internalError:
            "internalError"
        case .invalidTransform:
            "invalidTransform"
        case .commentKeyNotAllowed:
            "commentKeyNotAllowed"
        case .declaredHere:
            "declaredHere"
        }
    }

    var description: String {
        switch self {
        case .isNotEnum:
            "Only enums are supported"
        case .macroDeclarationHasNoArguments:
            "The macro declaration needs to have at least 1 String-Literal argument"
        case .unacceptableArguments:
            "The arguments passed to the macro were unacceptable"
        case .expectedAtLeastOneArgument:
            "At least one argument of type StaticString is required"
        case .invalidArgument:
            "Invalid argument received"
        case .expectedNonInterpolatedStringLiteral:
            "Expected a non-interpolated string literal"
        case let .renderedSyntaxContainsErrors(syntax):
            "Rendered syntax contains errors:\n\(syntax)"
        case let .couldNotFindLocationOfNode(syntax):
            "Could not find location of node for syntax:\n\(syntax)"
        case let .mustacheTemplateError(message):
            "Error while rendering the template: \(message)"
        case let .internalError(message):
            "An internal error occurred. Please file a bug report at https://github.com/mahdibm/enumerator-macro. Error:\n\(message)"
        case let .invalidTransform(transform, normalizedTypeName):
            "'\(normalizedTypeName)' doesn't have a function called '\(transform)'"
        case let .commentKeyNotAllowed(key):
            "Comment key '\(key)' is not allowed by the macro declaration"
        case let .declaredHere(name):
            "\(name) declared here"
        }
    }
}

extension MacroError: DiagnosticMessage {
    var message: String {
        self.description
    }

    var diagnosticID: MessageID {
        .init(domain: "EnumeratorMacro.MacroError", id: self.caseName)
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .declaredHere:
            return .note
        default:
            return .error
        }
    }
}
