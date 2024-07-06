import Testing
import XCTest
import SwiftParser
import SwiftSyntax
@testable import SyntaxKit

@Suite struct ParsedTypeTests {
    @Test private func parsesCorrectly() throws {
        let typeSyntax = try getTypeSyntax(for: "String")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed)")
        }
    }

    private func getTypeSyntax(for type: String) throws -> TypeSyntax {
        let code = "let variable: \(type)"
        let syntax = Parser.parse(source: code)
        try #require(!syntax.hasError)
        let statement = try #require(syntax.statements.first)
        let variableDeclaration = try #require(statement.item.as(VariableDeclSyntax.self))
        let binding = try #require(variableDeclaration.bindings.first)
        let typeAnnotation = try #require(binding.typeAnnotation)
        return typeAnnotation.type
    }
}
