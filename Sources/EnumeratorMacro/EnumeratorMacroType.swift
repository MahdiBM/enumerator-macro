import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
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
            fatalError("Not enum")
        }

        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap(\.elements)
        let cases = try elements.map(EnumCase.init(from:))

        guard let arguments = node.arguments else {
            fatalError("No arguments")
        }
        let rendered = try arguments.as(LabeledExprListSyntax.self)!.compactMap {
            $0.expression
        }.compactMap { expression in
            expression.as(StringLiteralExprSyntax.self)
        }.map { stringLiteralExpr in
            stringLiteralExpr
                .segments
                .formatted()
                .description
        }.map { template in
            try MustacheTemplate(string: "{{%CONTENT_TYPE:TEXT}}\n" + template)
                .render(["cases": cases])
        }.map(DeclSyntax.init(stringLiteral:))
        
        return rendered
    }
}
