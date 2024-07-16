import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros
import SwiftParser
import SwiftParserDiagnostics
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
        let cases = try ECases(elements: elements)

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
                .description
            return (template, stringLiteral)
        }
        let rendered = templates.compactMap {
            (template, syntax) -> (rendered: String, syntax: StringLiteralExprSyntax)? in
            do {
                let rendered: String? = try RenderingContext.$current.withValue(.init()) {
                    let result = try MustacheTemplate(
                        string: "{{%CONTENT_TYPE:TEXT}}\n" + template
                    ).render([
                        "cases": cases
                    ])
                    if let diagnostic = RenderingContext.current.diagnostic {
                        context.addDiagnostics(
                            from: diagnostic,
                            node: syntax
                        )
                        return nil
                    } else {
                        return result
                    }
                }
                guard let rendered else {
                    return nil
                }
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
                    if segmentIdx >= 0, segmentIdx < segments.count {
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
        typealias DeclWithOriginalSyntax = (DeclSyntax, StringLiteralExprSyntax)
        let syntaxes: [DeclWithOriginalSyntax] = rendered.compactMap {
            (rendered, codeSyntax)
            -> (declSyntaxes: [DeclSyntax], codeSyntax: StringLiteralExprSyntax)? in
            var parser = Parser(rendered)
            let decls = SourceFileSyntax.parse(
                from: &parser
            ).statements.compactMap { statement -> DeclSyntax? in
                let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: statement)
                let hasError = diagnostics.contains(where: { $0.diagMessage.severity == .error })
                if hasError {
                    context.diagnose(.init(
                        node: codeSyntax,
                        message: MacroError.renderedSyntaxContainsErrors(statement.description)
                    ))
                }
                for diagnostic in diagnostics {
                    if diagnostic.diagMessage.severity == .error {
                        context.diagnose(.init(
                            node: codeSyntax,
                            position: diagnostic.position,
                            message: diagnostic.diagMessage,
                            highlights: diagnostic.highlights,
                            notes: diagnostic.notes,
                            fixIts: diagnostic.fixIts
                        ))
                    } else if let /*fixIt*/_ = diagnostic.fixIts.first {
                        /// TODO: Apply the fixit
                    }
                }
                if hasError {
                    return nil
                }
                switch DeclSyntax(statement.item) {
                case let .some(declSyntax):
                    return declSyntax
                case .none:
                    context.diagnose(
                        Diagnostic(
                            node: codeSyntax,
                            message: MacroError.internalError(
                                "Could not convert a CodeBlockItemSyntax to a DeclSyntax"
                            )
                        )
                    )
                    return nil
                }
            }
            return (decls, codeSyntax)
        }.flatMap { result -> [DeclWithOriginalSyntax] in
            result.declSyntaxes.map {
                ($0, result.codeSyntax)
            }
        }
        let postProcessedSyntaxes = syntaxes.compactMap { 
            (syntax, codeSyntax) -> DeclSyntax? in
            let rewriter = Rewriter()
            let newSyntax = rewriter.rewrite(syntax)
            guard let declSyntax = DeclSyntax(newSyntax) else {
                context.diagnose(
                    Diagnostic(
                        node: codeSyntax,
                        message: MacroError.internalError(
                            "Could not convert a post-processed Syntax to a DeclSyntax"
                        )
                    )
                )
                return nil
            }
            return declSyntax
        }

        return postProcessedSyntaxes
    }
}
