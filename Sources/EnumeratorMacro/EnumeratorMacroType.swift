import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftParser
import Mustache

public enum EnumeratorMacroType {}

extension EnumeratorMacroType: MemberMacro {
    public static func expansion(
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
        let rendered = try arguments.as(LabeledExprListSyntax.self)!.compactMap {
            $0.expression
                .as(StringLiteralExprSyntax.self)?
                .segments
                .formatted()
                .description
        }.map { template in
            try MustacheTemplate(string: "{{%CONTENT_TYPE:TEXT}}\n" + template)
                .render(["cases": cases])
        }.map {
            var parser = Parser($0)
            return DeclSyntax.parse(from: &parser)
        }

        return rendered
    }
}
