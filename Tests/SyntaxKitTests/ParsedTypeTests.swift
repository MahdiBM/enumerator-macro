import Testing
import XCTest
import SwiftParser
import SwiftSyntax
import SyntaxKit

@Suite struct ParsedTypeTests {
    @Test func parseString() throws {
        let typeSyntax = try makeTypeSyntax(for: "String")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .identifier(syntax) = parsed {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseOptionalString() throws {
        let typeSyntax = try makeTypeSyntax(for: "String?")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .optional(wrapped) = parsed,
           case let .identifier(syntax) = wrapped {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseArrayOfDoubles() throws {
        let typeSyntax = try makeTypeSyntax(for: "[Double]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .array(element) = parsed,
           case let .identifier(syntax) = element {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseArrayOfOptionalDoubles() throws {
        let typeSyntax = try makeTypeSyntax(for: "[   Double? ]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .array(element) = parsed,
           case let .optional(wrapped) = element,
           case let .identifier(syntax) = wrapped {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseGenericOfSomeOfThingOfOptionalFoo() throws {
        let typeSyntax = try makeTypeSyntax(for: "Some<  Thing<Foo? >>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .unknownGeneric(first, arguments) = parsed,
           case let .identifier(firstSyntax) = first,
           arguments.count == 1,
           case let .unknownGeneric(second, arguments) = arguments.first,
           case let .identifier(secondSyntax) = second,
           arguments.count == 1,
           case let .optional(wrapped) = arguments.first,
           case let .identifier(third) = wrapped {
            #expect(firstSyntax.tokenKind == .identifier("Some"))
            #expect(secondSyntax.tokenKind == .identifier("Thing"))
            #expect(third.tokenKind == .identifier("Foo"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseGenericOfSomeOfThingOfOptionalFooAndBarAndBaz() throws {
        let typeSyntax = try makeTypeSyntax(for: "Some<Thing<Foo>, Bar, Baz>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case .unknownGeneric(let first, var baseArguments) = parsed,
           case let .identifier(firstSyntax) = first,
           baseArguments.count == 3,
           case let .unknownGeneric(second, arguments) = baseArguments.removeFirst(),
           case let .identifier(secondSyntax) = second,
           arguments.count == 1,
           case let .identifier(inSecondSyntax) = arguments.first,
           case let .identifier(thirdSyntax) = baseArguments.removeFirst(),
           case let .identifier(fourthSyntax) = baseArguments.removeFirst() {
            #expect(firstSyntax.tokenKind == .identifier("Some"))
            #expect(secondSyntax.tokenKind == .identifier("Thing"))
            #expect(inSecondSyntax.tokenKind == .identifier("Foo"))
            #expect(thirdSyntax.tokenKind == .identifier("Bar"))
            #expect(fourthSyntax.tokenKind == .identifier("Baz"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseTupleOfStringAndOptionalInt() throws {
        let typeSyntax = try makeTypeSyntax(for: "(String, Int, labeled: [MyType])")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case var .tuple(elements) = parsed,
           elements.count == 3 {
            let first = elements.removeFirst()
            let second = elements.removeFirst()
            let third = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type,
               first.firstName == nil,
               first.secondName == nil,
               case let .identifier(secondSyntax) = second.type,
               second.firstName == nil,
               second.secondName == nil,
               case let .array(thirdElementType) = third.type,
               case let .identifier(thirdSyntax) = thirdElementType,
               third.firstName?.tokenKind == .identifier("labeled"),
               third.secondName == nil {
                #expect(firstSyntax.tokenKind == .identifier("String"))
                #expect(secondSyntax.tokenKind == .identifier("Int"))
                #expect(thirdSyntax.tokenKind == .identifier("MyType"))
            } else {
                #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
            }
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseLabeledTupleOfStringAndOptionalInt() throws {
        let typeSyntax = try makeTypeSyntax(for: "(some _:String, _ thing:Int?)")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case var .tuple(elements) = parsed,
            elements.count == 2 {
            let first = elements.removeFirst()
            let second = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type,
               first.firstName?.tokenKind == .identifier("some"),
               first.secondName?.tokenKind == .wildcard,
               case let .optional(secondWrapped) = second.type,
               case let .identifier(secondSyntax) = secondWrapped,
               second.firstName?.tokenKind == .wildcard,
               second.secondName?.tokenKind == .identifier("thing") {
                #expect(firstSyntax.tokenKind == .identifier("String"))
                #expect(secondSyntax.tokenKind == .identifier("Int"))
            } else {
                #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
            }
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseDictionaryWithKeyOfBarOfBieAndValueOfAny() throws {
        let typeSyntax = try makeTypeSyntax(for: "[  Bar< Bie >:Any]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .dictionary(key, value) = parsed,
           case let .unknownGeneric(firstInKey, arguments) = key,
           case let .identifier(firstInKeySyntax) = firstInKey,
           arguments.count == 1,
           case let .identifier(secondInKey) = arguments.first,
           case let .identifier(valueSyntax) = value {
            #expect(firstInKeySyntax.tokenKind == .identifier("Bar"))
            #expect(secondInKey.tokenKind == .identifier("Bie"))
            #expect(valueSyntax.tokenKind == .keyword(.Any))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseOpaqueSomeOfThing() throws {
        let typeSyntax = try makeTypeSyntax(for: "some   Thing")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .some(type) = parsed,
           case let .identifier(syntax) = type {
            #expect(syntax.tokenKind == .identifier("Thing"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseOpaqueSomeOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "some   Bar<  Bie  >")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .some(type) = parsed,
           case let .unknownGeneric(first, arguments) = type,
           case let .identifier(firstSyntax) = first,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseExistentialAnyOfThing() throws {
        let typeSyntax = try makeTypeSyntax(for: "any   Thing")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .any(type) = parsed,
           case let .identifier(syntax) = type {
            #expect(syntax.tokenKind == .identifier("Thing"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseExistentialAnyOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "any Bar<  Bie>")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .any(type) = parsed,
           case let .unknownGeneric(first, arguments) = type,
           case let .identifier(firstSyntax) = first,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseNestedTypesOfFirstOfOptionalSecondOfThird() throws {
        let typeSyntax = try makeTypeSyntax(for: "First.Second?  .Third")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .member(`extension`, base) = parsed,
           case let .identifier(firstSyntax) = `extension`,
           case let .optional(wrapped) = base,
           case let .member(`extension`, base) = wrapped,
           case let .identifier(secondSyntax) = `extension`,
           case let .identifier(thirdSyntax) = base {
            #expect(firstSyntax.tokenKind == .identifier("Third"))
            #expect(secondSyntax.tokenKind == .identifier("Second"))
            #expect(thirdSyntax.tokenKind == .identifier("First"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseMetatype() throws {
        let typeSyntax = try makeTypeSyntax(for: "Foo  .Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .metatype(base) = parsed,
           case let .identifier(firstSyntax) = base {
            #expect(firstSyntax.tokenKind == .identifier("Foo"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseMetatypeOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "Bar<Bie>.Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .metatype(base) = parsed,
           case let .unknownGeneric(first, arguments) = base,
           case let .identifier(firstSyntax) = first,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseInferredType() throws {
        let typeSyntax = try makeTypeSyntax(for: "_")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .identifier(firstSyntax) = parsed {
            #expect(firstSyntax.tokenKind == .wildcard)
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseDictionaryWithKeyOfInferredTypeAndValueOfBool() throws {
        let typeSyntax = try makeTypeSyntax(for: "[_: Bool]")
        let parsed = try ParsedType(syntax: typeSyntax)
        if case let .dictionary(key, value) = parsed,
           case let .identifier(keySyntax) = key,
           case let .identifier(valueSyntax) = value {
            #expect(keySyntax.tokenKind == .wildcard)
            #expect(valueSyntax.tokenKind == .identifier("Bool"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    // TODO: More tests, for e.g. `descriptionWithoutOptionality()`

    private func makeTypeSyntax(for type: String) throws -> TypeSyntax {
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
