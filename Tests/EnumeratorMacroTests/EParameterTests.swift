import SwiftParser
import SwiftSyntax
import XCTest

@testable import EnumeratorMacroImpl

final class EParameterTests: XCTestCase {

    func testParameter() throws {
        let name = "name"
        let type = "String"
        let parameter = try makeParameter(
            firstName: .identifier(name),
            secondName: nil,
            type: type
        )

        XCTAssertEqual(parameter.name.underlying, name)
        XCTAssertEqual(parameter.type.underlying, type)
        XCTAssertEqual(parameter.isOptional, false)
    }

    func testParameterWithSecondName() throws {
        let name = "name"
        let secondName = "secondName"
        let type = "String"
        let parameter = try makeParameter(
            firstName: .identifier(name),
            secondName: .identifier(secondName),
            type: type
        )

        XCTAssertEqual(parameter.name.underlying, secondName)
        XCTAssertEqual(parameter.type.underlying, type)
        XCTAssertEqual(parameter.isOptional, false)
    }

    func testParameterWithOptionalType() throws {
        let name = "name"
        let type = "String?"
        let parameter = try makeParameter(
            firstName: .identifier(name),
            secondName: nil,
            type: type
        )

        XCTAssertEqual(parameter.name.underlying, name)
        XCTAssertEqual(parameter.type.underlying, type)
        XCTAssertEqual(parameter.isOptional, true)
    }

    func testParameterWithImplicitlyOptionalType() throws {
        let name = "name"
        let type = "Int!"
        let parameter = try makeParameter(
            firstName: .identifier(name),
            secondName: nil,
            type: type
        )

        XCTAssertEqual(parameter.name.underlying, name)
        XCTAssertEqual(parameter.type.underlying, type)
        XCTAssertEqual(parameter.isOptional, true)
    }

    func testParameterWithSpelledOutOptionalType() throws {
        let name = "name"
        let type = "Optional<Thing>"
        let parameter = try makeParameter(
            firstName: .identifier(name),
            secondName: nil,
            type: type
        )

        XCTAssertEqual(parameter.name.underlying, name)
        XCTAssertEqual(parameter.type.underlying, type)
        XCTAssertEqual(parameter.isOptional, true)
    }

    private func makeParameter(
        firstName: TokenSyntax,
        secondName: TokenSyntax?,
        type: String
    ) throws -> EParameter {
        EParameter(
            from: EnumCaseParameterSyntax(
                firstName: firstName,
                secondName: secondName,
                type: try makeTypeSyntax(for: type)
            ),
            index: .random(in: .min ... .max),
            isFirst: .random(),
            isLast: .random()
        )
    }

    private func makeTypeSyntax(for type: String) throws -> TypeSyntax {
        let code = "let variable: \(type)"
        let syntax = Parser.parse(source: code)
        XCTAssertFalse(syntax.hasError)
        let statement = try XCTUnwrap(syntax.statements.first)
        let variableDeclaration = try XCTUnwrap(statement.item.as(VariableDeclSyntax.self))
        let binding = try XCTUnwrap(variableDeclaration.bindings.first)
        let typeAnnotation = try XCTUnwrap(binding.typeAnnotation)
        return typeAnnotation.type
    }
}
