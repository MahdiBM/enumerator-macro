import Testing
import XCTest
import SwiftParser
import SwiftSyntax
import SyntaxKit

@Suite struct ParsedTypeTests {
    @Test func parseString() throws {
        let typeSyntax = try makeTypeSyntax(for: "String")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .identifier(syntax) = parsed.type {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseOptionalString() throws {
        let typeSyntax = try makeTypeSyntax(for: "String?")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .optional(wrapped) = parsed.type,
           case let .identifier(syntax) = wrapped.type {
            #expect(syntax.tokenKind == .identifier("String"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseArrayOfDoubles() throws {
        let typeSyntax = try makeTypeSyntax(for: "[Double]")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .array(element) = parsed.type,
           case let .identifier(syntax) = element.type {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseArrayOfOptionalDoubles() throws {
        let typeSyntax = try makeTypeSyntax(for: "[   Double? ]")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .array(element) = parsed.type,
           case let .optional(wrapped) = element.type,
           case let .identifier(syntax) = wrapped.type {
            #expect(syntax.tokenKind == .identifier("Double"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseGenericOfSomeOfThingOfOptionalFoo() throws {
        let typeSyntax = try makeTypeSyntax(for: "Some<  Thing<Foo? >>")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .unknownGeneric(first, arguments) = parsed.type,
           case let .identifier(firstSyntax) = first.type,
           arguments.count == 1,
           case let .unknownGeneric(second, arguments) = arguments.first?.type,
           case let .identifier(secondSyntax) = second.type,
           arguments.count == 1,
           case let .optional(wrapped) = arguments.first?.type,
           case let .identifier(third) = wrapped.type {
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
        #expect(parsed.syntax == typeSyntax)
        if case .unknownGeneric(let first, var baseArguments) = parsed.type,
           case let .identifier(firstSyntax) = first.type,
           baseArguments.count == 3,
           case let .unknownGeneric(second, arguments) = baseArguments.removeFirst().type,
           case let .identifier(secondSyntax) = second.type,
           arguments.count == 1,
           case let .identifier(inSecondSyntax) = arguments.first?.type,
           case let .identifier(thirdSyntax) = baseArguments.removeFirst().type,
           case let .identifier(fourthSyntax) = baseArguments.removeFirst().type {
            #expect(firstSyntax.tokenKind == .identifier("Some"))
            #expect(secondSyntax.tokenKind == .identifier("Thing"))
            #expect(inSecondSyntax.tokenKind == .identifier("Foo"))
            #expect(thirdSyntax.tokenKind == .identifier("Bar"))
            #expect(fourthSyntax.tokenKind == .identifier("Baz"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseTupleOfDouble() throws {
        let typeSyntax = try makeTypeSyntax(for: "(Double)")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case var .tuple(elements) = parsed.type,
           elements.count == 1 {
            let first = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type {
                #expect(firstSyntax.tokenKind == .identifier("Double"))
            } else {
                #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
            }
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseTupleOfStringAndInferretTypeAndArrayOfMyType() throws {
        let typeSyntax = try makeTypeSyntax(for: "(String, _, labeled: [MyType])")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case var .tuple(elements) = parsed.type,
           elements.count == 3 {
            let first = elements.removeFirst()
            let second = elements.removeFirst()
            let third = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type,
               case let .identifier(secondSyntax) = second.type,
               case let .array(thirdElementType) = third.type,
               case let .identifier(thirdSyntax) = thirdElementType.type {
                #expect(firstSyntax.tokenKind == .identifier("String"))
                #expect(secondSyntax.tokenKind == .wildcard)
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
        #expect(parsed.syntax == typeSyntax)
        if case var .tuple(elements) = parsed.type,
            elements.count == 2 {
            let first = elements.removeFirst()
            let second = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type,
               case let .optional(secondWrapped) = second.type,
               case let .identifier(secondSyntax) = secondWrapped.type {
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
        #expect(parsed.syntax == typeSyntax)
        if case let .dictionary(key, value) = parsed.type,
           case let .unknownGeneric(firstInKey, arguments) = key.type,
           case let .identifier(firstInKeySyntax) = firstInKey.type,
           arguments.count == 1,
           case let .identifier(secondInKey) = arguments.first?.type,
           case let .identifier(valueSyntax) = value.type {
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
        #expect(parsed.syntax == typeSyntax)
        if case let .some(type) = parsed.type,
           case let .identifier(syntax) = type.type {
            #expect(syntax.tokenKind == .identifier("Thing"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseOpaqueSomeOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "some   Bar<  Bie  >")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .some(type) = parsed.type,
           case let .unknownGeneric(first, arguments) = type.type,
           case let .identifier(firstSyntax) = first.type,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first?.type {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseExistentialAnyOfThing() throws {
        let typeSyntax = try makeTypeSyntax(for: "any   Thing")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .any(type) = parsed.type,
           case let .identifier(syntax) = type.type {
            #expect(syntax.tokenKind == .identifier("Thing"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseExistentialAnyOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "any Bar<  Bie>")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .any(type) = parsed.type,
           case let .unknownGeneric(first, arguments) = type.type,
           case let .identifier(firstSyntax) = first.type,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first?.type {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseNestedTypesOfFirstOfOptionalSecondOfThird() throws {
        let typeSyntax = try makeTypeSyntax(for: "First.Second?  .Third")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .member(base, `extension`) = parsed.type,
           case let .identifier(firstSyntax) = `extension`.type,
           case let .optional(wrapped) = base.type,
           case let .member(base, `extension`) = wrapped.type,
           case let .identifier(secondSyntax) = `extension`.type,
           case let .identifier(thirdSyntax) = base.type {
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
        #expect(parsed.syntax == typeSyntax)
        if case let .metatype(base) = parsed.type,
           case let .identifier(firstSyntax) = base.type {
            #expect(firstSyntax.tokenKind == .identifier("Foo"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseMetatypeOfBarOfBie() throws {
        let typeSyntax = try makeTypeSyntax(for: "Bar<Bie>.Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .metatype(base) = parsed.type,
           case let .unknownGeneric(first, arguments) = base.type,
           case let .identifier(firstSyntax) = first.type,
           arguments.count == 1,
           case let .identifier(secondSyntax) = arguments.first?.type {
            #expect(firstSyntax.tokenKind == .identifier("Bar"))
            #expect(secondSyntax.tokenKind == .identifier("Bie"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseLabeledMetatypeTupleOfSomeDecodable() throws {
        let typeSyntax = try makeTypeSyntax(for: "(some Decodable).Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .metatype(type) = parsed.type,
           case var .tuple(elements) = type.type,
           elements.count == 1 {
            let first = elements.removeFirst()
            if case let .some(firstType) = first.type,
               case let .identifier(firstSyntax) = firstType.type {
                #expect(firstSyntax.tokenKind == .identifier("Decodable"))
            } else {
                #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
            }
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseLabeledMetatypeTupleOfStringAndOptionalInt() throws {
        let typeSyntax = try makeTypeSyntax(for: "(some _:String, _ thing:Int?).Type")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .metatype(type) = parsed.type,
           case var .tuple(elements) = type.type,
           elements.count == 2 {
            let first = elements.removeFirst()
            let second = elements.removeFirst()
            if case let .identifier(firstSyntax) = first.type,
               case let .optional(secondWrapped) = second.type,
               case let .identifier(secondSyntax) = secondWrapped.type {
                #expect(firstSyntax.tokenKind == .identifier("String"))
                #expect(secondSyntax.tokenKind == .identifier("Int"))
            } else {
                #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
            }
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseInferredType() throws {
        let typeSyntax = try makeTypeSyntax(for: "_")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .identifier(firstSyntax) = parsed.type {
            #expect(firstSyntax.tokenKind == .wildcard)
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

    @Test func parseDictionaryWithKeyOfInferredTypeAndValueOfBool() throws {
        let typeSyntax = try makeTypeSyntax(for: "[_: Bool]")
        let parsed = try ParsedType(syntax: typeSyntax)
        #expect(parsed.syntax == typeSyntax)
        if case let .dictionary(key, value) = parsed.type,
           case let .identifier(keySyntax) = key.type,
           case let .identifier(valueSyntax) = value.type {
            #expect(keySyntax.tokenKind == .wildcard)
            #expect(valueSyntax.tokenKind == .identifier("Bool"))
        } else {
            #expect(Bool(false), "Unexpected 'ParsedType': \(parsed.debugDescription)")
        }
    }

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
