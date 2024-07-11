import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftParser
import Mustache
import Foundation

enum EnumeratorMacroType {}

extension EnumeratorMacroType: MemberMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if declaration.hasError { return [] }

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw MacroError.isNotEnum
        }

        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap(\.elements)
        let cases = try elements.map(EnumCase.init(from:))

        guard let arguments = node.arguments else {
            throw MacroError.macroDeclarationHasNoArguments
        }
        guard let exprList = arguments.as(LabeledExprListSyntax.self) else {
            throw MacroError.unacceptableArguments
        }
        if exprList.isEmpty {
            throw MacroError.expectedAtLeastOneArgument
        }
        let templates = try exprList.compactMap { 
            element -> (template: String, syntax: StringLiteralExprSyntax) in
            guard let stringLiteral = element.expression.as(StringLiteralExprSyntax.self) else {
                throw MacroError.allArgumentsMustBeStringLiterals(violation: element.description)
            }
            let template = stringLiteral
                .segments
                .formatted()
                .description
            return (template, stringLiteral)
        }
        let rendered = templates.compactMap {
            (template, syntax) -> (rendered: String, syntax: StringLiteralExprSyntax)? in
            do {
                let rendered = try MustacheTemplate(
                    string: "{{%CONTENT_TYPE:TEXT}}\n" + template
                ).render([
                    "cases": cases
                ])
                return (rendered, syntax)
            } catch {
                let message: MacroError
                let errorSyntax: SyntaxProtocol
                if let parserError = error as? MustacheTemplate.ParserError {
                    message = .mustacheTemplateError(
                        message: String(describing: parserError.error)
                    )
                    let segments = Array(syntax.segments)
                    let segmentIdx = parserError.context.lineNumber - 2
                    if segmentIdx < segments.count {
                        let syntaxAtErrorLine = segments[segmentIdx]
                        errorSyntax = syntaxAtErrorLine
                    } else {
                        errorSyntax = syntax
                    }
                } else {
                    message = .mustacheTemplateError(
                        message: String(describing: error)
                    )
                    errorSyntax = syntax
                }
                context.diagnose(
                    Diagnostic(
                        node: errorSyntax,
                        message: message
                    )
                )
                return nil
            }
        }
        let syntaxes: [DeclSyntax] = rendered.compactMap {
            (rendered, syntax) -> [DeclSyntax]? in
            let decls = SourceFileSyntax(
                stringLiteral: rendered
            ).statements.compactMap { statement in
                DeclSyntax(statement.item)
            }
            if let withError = decls.first(where: \.hasError) {
                context.diagnose(
                    Diagnostic(
                        node: syntax,
                        message: MacroError.renderedSyntaxContainsErrors(withError.description)
                    )
                )
                return nil
            }
            return decls
        }.flatMap { $0 }

        return syntaxes
    }
}
