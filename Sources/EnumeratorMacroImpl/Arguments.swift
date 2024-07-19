import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics

struct Arguments {

    struct AllowedComments {
        let node: ArrayExprSyntax
        var keys: [String]
    }

    var templates: [(String, StringLiteralExprSyntax)] = []
    var allowedComments: AllowedComments?

    init(
        arguments: AttributeSyntax.Arguments,
        context: some MacroExpansionContext
    ) throws {
        guard let exprList = arguments.as(LabeledExprListSyntax.self) else {
            throw MacroError.unacceptableArguments
        }
        if exprList.isEmpty {
            throw MacroError.expectedAtLeastOneValidArgument
        }
        for element in exprList {
            switch element.expression.kind {
            case .stringLiteralExpr:
                self.handleTemplateArgument(
                    element: element,
                    context: context
                )
            case .arrayExpr where element.label?.tokenKind == .identifier("allowedComments"):
                self.handleComments(
                    element: element,
                    context: context
                )
            default:
                context.diagnose(
                    Diagnostic(
                        node: element,
                        message: MacroError.invalidArgument
                    )
                )
            }
        }
    }

    private mutating func handleComments(
        element: LabeledExprSyntax,
        context: some MacroExpansionContext
    ) {
        guard let array = element.expression.as(ArrayExprSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: element.expression,
                    message: MacroError.internalError(
                        "Expected a guaranteed 'StringLiteralExprSyntax', but got '\(type(of: element))'"
                    )
                )
            )
            return
        }

        /// `allowedComments` initialized, all below declarations can force-unwrap
        self.allowedComments = .init(node: array, keys: [])

        self.allowedComments!.keys.reserveCapacity(array.elements.count)
        for value in array.elements {
            guard let stringLiteral = value.expression.as(StringLiteralExprSyntax.self) else {
                context.diagnose(
                    Diagnostic(
                        node: value.expression,
                        message: MacroError.expectedNonInterpolatedStringLiteral
                    )
                )
                continue
            }
            guard let string = self.requireStringLiteralOrThrowDiagnostic(
                node: stringLiteral,
                context: context
            ) else { continue }
            self.allowedComments!.keys.append(string)
        }
    }

    private mutating func handleTemplateArgument(
        element: LabeledExprSyntax,
        context: some MacroExpansionContext
    ) {
        guard let stringLiteral = element.expression.as(StringLiteralExprSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: element.expression,
                    message: MacroError.internalError(
                        "Expected a guaranteed 'StringLiteralExprSyntax', but got '\(type(of: element))'"
                    )
                )
            )
            return
        }
        guard let template = self.requireStringLiteralOrThrowDiagnostic(
            node: stringLiteral,
            context: context
        ) else {
            return
        }
        self.templates.append((template, stringLiteral))
    }

    private func requireStringLiteralOrThrowDiagnostic(
        node: StringLiteralExprSyntax,
        context: some MacroExpansionContext
    ) -> String? {
        var hadBadSegment = false
        for segment in node.segments where !segment.is(StringSegmentSyntax.self) {
            context.diagnose(
                Diagnostic(
                    node: segment,
                    message: MacroError.expectedNonInterpolatedStringLiteral
                )
            )
            hadBadSegment = true
        }
        if hadBadSegment { return nil }

        return node.segments.description
    }
}
