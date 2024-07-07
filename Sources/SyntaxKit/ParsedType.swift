import SwiftSyntax

public indirect enum ParsedType {
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

    public struct TupleElement {
        public let firstName: TokenSyntax?
        public let secondName: TokenSyntax?
        public let type: ParsedType
    }

    case identifier(TokenSyntax)
    case optional(of: Self)
    case array(of: Self)
    case dictionary(key: Self, value: Self)
    case tuple(of: [TupleElement])
    case some(of: Self)
    case any(of: Self)
    case member(`extension`: Self, base: Self)
    case metatype(base: Self)
    case unknownGeneric(Self, arguments: [Self])

    public func descriptionWithoutOptionality() -> (isOptional: Bool, description: String) {
        switch self {
        case let .optional(type):
            (true, type.description)
        default:
            (false, self.description)
        }
    }

    public var isOptional: Bool {
        switch self {
        case .optional:
            true
        default:
            false
        }
    }

    public init(syntax: some TypeSyntaxProtocol) throws {
        if let type = syntax.as(IdentifierTypeSyntax.self) {
            let name = type.name.trimmed
            if let genericArgumentClause = type.genericArgumentClause,
               !genericArgumentClause.arguments.isEmpty {
                let arguments = genericArgumentClause.arguments
                switch (arguments.count, name.trimmedDescription) { // FIXME: Change from TRIMMED
                case (1, "Optional"):
                    self = try .optional(of: Self(syntax: arguments.first!.argument))
                case (1, "Array"):
                    self = try .array(of: Self(syntax: arguments.first!.argument))
                case (2, "Dictionary"):
                    let key = try Self(syntax: arguments.first!.argument)
                    let value = try Self(syntax: arguments.last!.argument)
                    self = .dictionary(key: key, value: value)
                default:
                    let arguments = try arguments.map(\.argument).map(Self.init(syntax:))
                    self = .unknownGeneric(.identifier(name), arguments: arguments)
                }
            } else {
                self = .identifier(name)
            }
        } else if let type = syntax.as(OptionalTypeSyntax.self) {
            self = try .optional(of: Self(syntax: type.wrappedType))
        } else if let type = syntax.as(ArrayTypeSyntax.self) {
            self = try .array(of: Self(syntax: type.element))
        } else if let type = syntax.as(DictionaryTypeSyntax.self) {
            let key = try Self(syntax: type.key)
            let value = try Self(syntax: type.value)
            self = .dictionary(key: key, value: value)
        } else if let type = syntax.as(TupleTypeSyntax.self) {
            let elements = try type.elements.map { element in
                try TupleElement(
                    firstName: element.firstName,
                    secondName: element.secondName,
                    type: Self(syntax: element.type)
                )
            }
            self = .tuple(of: elements)
        } else if let type = syntax.as(SomeOrAnyTypeSyntax.self) {
            let constraint = try Self(syntax: type.constraint)
            switch type.someOrAnySpecifier.tokenKind {
            case .keyword(.some):
                self = .some(of: constraint)
            case .keyword(.any):
                self = .any(of: constraint)
            default:
                throw Error.unknownSomeOrAnySpecifier(
                    token: type.someOrAnySpecifier
                )
            }
        } else if let type = syntax.as(MemberTypeSyntax.self) {
            let base = try Self(syntax: type.baseType)
            let `extension` = ParsedType.identifier(type.name)
            self = .member(extension: `extension`, base: base)
        } else if let type = syntax.as(MetatypeTypeSyntax.self) {
            let baseType = try Self(syntax: type.baseType)
            self = .metatype(base: baseType)
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

extension ParsedType: CustomDebugStringConvertible {
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

extension ParsedType.TupleElement: CustomStringConvertible {
    public var description: String {
        "ParsedType.TupleElement(firstName: \(String(describing: self.firstName)), secondName: \(String(describing: self.secondName)), type: \(self.type))"
    }
}

extension ParsedType.TupleElement: CustomDebugStringConvertible {
    public var debugDescription: String {
        "ParsedType.TupleElement(firstName: \(String(reflecting: self.firstName)), secondName: \(String(reflecting: self.secondName)), type: \(self.type.debugDescription))"
    }
}
