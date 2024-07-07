public import SwiftSyntax

/// A parsed `TypeSyntax`.
public struct ParsedType {
    enum Error: Swift.Error, CustomStringConvertible {
        case unknownParameterType(String, syntaxType: Any.Type)
        case unknownSomeOrAnySpecifier(token: TokenSyntax)

        var description: String {
            switch self {
            case let .unknownParameterType(type, syntaxType):
                "unknownParameterType(\(type), syntaxType: \(syntaxType))"
            case let .unknownSomeOrAnySpecifier(token):
                "unknownSomeOrAnySpecifier(token: \(token))"
            }
        }
    }

    public indirect enum BaseType {
        /// A simple type identifier.
        /// Example: `String`, `MyType`.
        case identifier(TokenSyntax)
        /// An optional type.
        /// Example: `Bool?`.
        case optional(of: ParsedType)
        /// An array.
        /// Example: `[Double]`, `Array<MyType>`.
        case array(of: ParsedType)
        /// A dictionary.
        /// Example: `[String: Bool]`, `[_: UInt]`.
        case dictionary(key: ParsedType, value: ParsedType)
        /// A tuple.
        /// Example: `(String)`, `(val1 _: String, val2: _, _ val3: MyType)`.
        case tuple(of: [ParsedType])
        /// An opaque-`some` type.
        /// Example: `some StringProtocol`, `some View`.
        case some(of: ParsedType)
        /// An existential-`any` type.
        /// Example: `any StringProtocol`, `any Decodable`.
        case any(of: ParsedType)
        /// A member type.
        /// Example: `String.Iterator`, `ContinuousClock.Duration`, `Foo.Bar.Baz`.
        /// In `String.Iterator`, `String` is `base` and `Iterator` is `extension`.
        /// In `Foo.Bar.Baz`, `Foo.Bar` is `base` (of another `ParsedType.member`) and `Baz` is `extension`.
        case member(base: ParsedType, `extension`: ParsedType)
        /// A metatype.
        /// Example: `String.Type`, `(some Decodable).Type`, `(Int, String).Type`.
        case metatype(base: ParsedType)
        /// A generic type other than the ones above (`Optional`, `Array`, `Dictionary`).
        /// Example: `Collection<String>`, `Result<Response, any Error>`.
        case unknownGeneric(ParsedType, arguments: [ParsedType])
    }

    public let syntax: TypeSyntax?
    public let type: BaseType

    private init(syntax: TypeSyntax?, type: BaseType) {
        self.syntax = syntax
        self.type = type
    }

    private static func identifier(_ identifier: TokenSyntax) -> Self {
        ParsedType(syntax: nil, type: .identifier(identifier))
    }

    /// Parses any `TypeSyntax`.
    public init(syntax: some TypeSyntaxProtocol) throws {
        self.syntax = TypeSyntax(syntax)
        if let type = syntax.as(IdentifierTypeSyntax.self) {
            let name = type.name.trimmed
            if let genericArgumentClause = type.genericArgumentClause,
               !genericArgumentClause.arguments.isEmpty {
                let arguments = genericArgumentClause.arguments
                switch (arguments.count, name.trimmedDescription) { // FIXME: Change from TRIMMED
                case (1, "Optional"):
                    self.type = try .optional(of: Self(syntax: arguments.first!.argument))
                case (1, "Array"):
                    self.type = try .array(of: Self(syntax: arguments.first!.argument))
                case (2, "Dictionary"):
                    let key = try Self(syntax: arguments.first!.argument)
                    let value = try Self(syntax: arguments.last!.argument)
                    self.type = .dictionary(key: key, value: value)
                default:
                    let arguments = try arguments.map(\.argument).map(Self.init(syntax:))
                    let base = ParsedType.identifier(name)
                    self.type = .unknownGeneric(base, arguments: arguments)
                }
            } else {
                self.type = .identifier(name)
            }
        } else if let type = syntax.as(OptionalTypeSyntax.self) {
            self.type = try .optional(of: Self(syntax: type.wrappedType))
        } else if let type = syntax.as(ArrayTypeSyntax.self) {
            self.type = try .array(of: Self(syntax: type.element))
        } else if let type = syntax.as(DictionaryTypeSyntax.self) {
            let key = try Self(syntax: type.key)
            let value = try Self(syntax: type.value)
            self.type = .dictionary(key: key, value: value)
        } else if let type = syntax.as(TupleTypeSyntax.self) {
            let elements = try type.elements.map {
                try Self(syntax: $0.type)
            }
            self.type = .tuple(of: elements)
        } else if let type = syntax.as(SomeOrAnyTypeSyntax.self) {
            let constraint = try Self(syntax: type.constraint)
            switch type.someOrAnySpecifier.tokenKind {
            case .keyword(.some):
                self.type = .some(of: constraint)
            case .keyword(.any):
                self.type = .any(of: constraint)
            default:
                throw Error.unknownSomeOrAnySpecifier(
                    token: type.someOrAnySpecifier
                )
            }
        } else if let type = syntax.as(MemberTypeSyntax.self) {
            let base = try Self(syntax: type.baseType)
            let `extension` = ParsedType.identifier(type.name)
            self.type = .member(base: base, extension: `extension`)
        } else if let type = syntax.as(MetatypeTypeSyntax.self) {
            let baseType = try Self(syntax: type.baseType)
            self.type = .metatype(base: baseType)
        } else {
            throw Error.unknownParameterType(
                syntax.trimmed.description,
                syntaxType: syntax.syntaxNodeType
            )
        }
    }
}

extension ParsedType: CustomStringConvertible {
    public var description: String {
        "ParsedType(syntax: \(String(describing: self.syntax)), type: \(self.type))"
    }
}

extension ParsedType: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ParsedType(syntax: \(String(reflecting: self.syntax)), type: \(self.type.debugDescription))"
    }
}

extension ParsedType.BaseType: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .identifier(type):
            "\(type.trimmed.description)"
        case let .optional(type):
            "\(type)?"
        case let .array(type):
            "[\(type)]"
        case let .dictionary(key, value):
            "[\(key): \(value)]"
        case let .tuple(elements):
            "(\(elements.map(\.description).joined(separator: ", ")))"
        case let .some(type):
            "some \(type)"
        case let .any(type):
            "any \(type)"
        case let .member(base, `extension`):
            "\(base.description).\(`extension`)"
        case let .metatype(base):
            "\(base.description).Type"
        case let .unknownGeneric(name, arguments: arguments):
            "\(name)<\(arguments.map(\.description).joined(separator: ", "))>"
        }
    }
}

extension ParsedType.BaseType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .identifier(type):
            "\(type.trimmed.debugDescription)"
        case let .optional(type):
            "\(type.debugDescription)?"
        case let .array(type):
            "[\(type.debugDescription)]"
        case let .dictionary(key, value):
            "[\(key.debugDescription): \(value.debugDescription)]"
        case let .tuple(elements):
            "(\(elements.map(\.debugDescription).joined(separator: ", ")))"
        case let .some(type):
            "some \(type.debugDescription)"
        case let .any(type):
            "any \(type.debugDescription)"
        case let .member(base, `extension`):
            "\(base.debugDescription).\(`extension`.debugDescription)"
        case let .metatype(base):
            "\(base.debugDescription).Type"
        case let .unknownGeneric(name, arguments: arguments):
            "\(name.debugDescription)<\(arguments.map(\.debugDescription).joined(separator: ", "))>"
        }
    }
}
