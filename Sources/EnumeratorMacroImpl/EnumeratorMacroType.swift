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

        let assignedMacroName = node.attributeName.description
        var templateFromFile: String?
        if assignedMacroName != "Enumerator" {
            let fm = FileManager.default
            var workingDirectory: String!
#if Xcode
            let byDotBuild = #filePath.components(separatedBy: "/.build/")
            if byDotBuild.count > 1 {
                workingDirectory = byDotBuild[0]
            } else {
                let bySources = #filePath.components(separatedBy: "/Sources/")
                if bySources.count > 1 {
                    workingDirectory = bySources[0]
                }
            }
            if workingDirectory == nil {
                throw MacroError.customNameIsEnteredForMacroButCannotFindWorkingDirectory(
                    name: assignedMacroName
                )
            }
#else
            dir = fm.currentDirectoryPath
#endif
            let path = workingDirectory + "/macro-templates/\(assignedMacroName).mustache"
            if fm.fileExists(atPath: path) {
                let data = try Data(contentsOf: .init(filePath: path))
                templateFromFile = String(decoding: data, as: UTF8.self)
            } else {
                throw MacroError.customNameIsEnteredForMacroButFileDoesNotExist(
                    name: assignedMacroName,
                    path: path
                )
            }
        }

        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap(\.elements)
        let cases = try elements.map(EnumCase.init(from:))

        func findTemplates() throws -> [String] {
            if let templateFromFile {
                return [templateFromFile]
            }

            guard let arguments = node.arguments else {
                throw MacroError.macroDeclarationHasNoArguments
            }
            guard let exprList = arguments.as(LabeledExprListSyntax.self) else {
                throw MacroError.unacceptableArguments
            }
            if exprList.isEmpty {
                throw MacroError.expectedAtLeastOneArgument
            }
            let stringLiteralArguments = try exprList.compactMap { element in
                guard let stringLiteral = element.expression.as(StringLiteralExprSyntax.self) else {
                    throw MacroError.allArgumentsMustBeStringLiterals(violation: element.description)
                }
                return stringLiteral
                    .segments
                    .formatted()
                    .description
            }
            return stringLiteralArguments
        }

        let rendered = try findTemplates().map { template in
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

        if let first = syntaxes.first(where: \.hasError) {
            throw MacroError.renderedSyntaxContainsErrors(first.description)
        }

        return syntaxes
    }
}
