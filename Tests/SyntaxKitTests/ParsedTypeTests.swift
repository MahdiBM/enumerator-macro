import Testing
import XCTest
import SwiftParser
import SwiftSyntax
import SyntaxKit

@Suite struct ParsedTypeTests {
    @Test private func parseString() throws {
        let typeSyntax = try getTypeSyntax(for: "String")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseOptionalString() throws {
        let typeSyntax = try getTypeSyntax(for: "String?")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .optional(wrapped) = parsed,
           case let .plain(syntax) = wrapped {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseArrayOfDoubles() throws {
        let typeSyntax = try getTypeSyntax(for: "[Double]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .array(element) = parsed,
           case let .plain(syntax) = element {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseArrayOfOptionalDoubles() throws {
        let typeSyntax = try getTypeSyntax(for: "[Double?]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .array(element) = parsed,
           case let .optional(wrapped) = element,
           case let .plain(syntax) = wrapped {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseGenericOfSomeOfThingOfOptionalFoo() throws {
        let typeSyntax = try getTypeSyntax(for: "Some<  Thing<Foo? >>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .unknownGeneric(first, arguments) = parsed,
           case let .plain(firstSyntax) = first,
           arguments.count == 1,
           case let .unknownGeneric(second, arguments) = arguments.first,
           case let .plain(secondSyntax) = second,
           arguments.count == 1,
           case let .optional(wrapped) = arguments.first,
           case let .plain(third) = wrapped {
            #expect(firstSyntax.tokenKind == .identifier("Some"))
            #expect(secondSyntax.tokenKind == .identifier("Thing"))
            #expect(third.tokenKind == .identifier("Foo"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseGenericOfSomeOfThingOfOptionalFooAndBarAndBaz() throws {
        let typeSyntax = try getTypeSyntax(for: "Some<Thing<Foo>, Bar, Baz>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .unknownGeneric(first, arguments) = parsed,
           case let .plain(firstSyntax) = first,
           arguments.count == 1,
           case let .unknownGeneric(second, arguments) = arguments.first,
           case let .plain(secondSyntax) = second,
           arguments.count == 1,
           case let .plain(third) = arguments.first {
            #expect(firstSyntax.tokenKind == .identifier("Some"))
            #expect(secondSyntax.tokenKind == .identifier("Thing"))
            #expect(third.tokenKind == .identifier("Foo"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseLabeledTupleOfStringAndOptionalInt() throws {
        let typeSyntax = try getTypeSyntax(for: "(some: String, thing: Int?)")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseTupleOfStringAndOptionalInt() throws {
        let typeSyntax = try getTypeSyntax(for: "(String, Int)")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseDictionaryWithKeyOfBarOfBieAndValueOfAny() throws {
        let typeSyntax = try getTypeSyntax(for: "[Bar<Bie>  : Any]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .dictionary(key, value) = parsed,
           case let .unknownGeneric(firstInKey, arguments) = key,
           case let .plain(firstInKeySyntax) = firstInKey,
           arguments.count == 1,
           case let .plain(secondInKey) = arguments.first,
           case let .plain(valueSyntax) = value {
            #expect(firstInKeySyntax.tokenKind == .identifier("Bar"))
            #expect(secondInKey.tokenKind == .identifier("Bie"))
            #expect(valueSyntax.tokenKind == .keyword(.Any))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseOpaqueSomeOfThing() throws {
        let typeSyntax = try getTypeSyntax(for: "some Thing")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseOpaqueSomeOfBarOfBie() throws {
        let typeSyntax = try getTypeSyntax(for: "some Bar<Bie>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseExistentialAnyOfThing() throws {
        let typeSyntax = try getTypeSyntax(for: "any Thing")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseExistentialAnyOfBarOfBie() throws {
        let typeSyntax = try getTypeSyntax(for: "any Bar<Bie>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseNestedTypesOfFirstOfOptionalSecondOfThird() throws {
        let typeSyntax = try getTypeSyntax(for: "First.Second?.Third")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .member(base, first) = parsed,
           case let .plain(firstSyntax) = first,
           case let .member(base, second) = base,
           case let .optional(wrappedOfSecond) = second,
           case let .plain(unwrappedOfSecond) = wrappedOfSecond,
           case let .plain(third) = base {
            #expect(firstSyntax.tokenKind == .identifier("First"))
            #expect(unwrappedOfSecond.tokenKind == .identifier("Second"))
            #expect(third.tokenKind == .identifier("Third"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseMetatype() throws {
        let typeSyntax = try getTypeSyntax(for: "Foo.Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test private func parseMetatypeOfBarOfBie() throws {
        let typeSyntax = try getTypeSyntax(for: "Bar<Bie>.Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .plain(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
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
