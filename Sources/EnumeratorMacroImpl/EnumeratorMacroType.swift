import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftParser
import Mustache

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
        let exprList = arguments.as(LabeledExprListSyntax.self)!
        let stringLiteralArguments = exprList.compactMap {
            $0.expression
                .as(StringLiteralExprSyntax.self)?
                .segments
                .formatted()
                .description
        }
        let rendered = try stringLiteralArguments.map { template in
            try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render([
                "cases": cases
            ])
        }
        let syntaxes: [DeclSyntax] = rendered.flatMap { rendered in
            SourceFileSyntax(
                stringLiteral: rendered
            ).statements.compactMap { statement in
                DeclSyntax(statement.item)
            }
        }

        return syntaxes
    }
}