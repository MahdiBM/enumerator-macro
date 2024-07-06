import SwiftSyntax

public indirect enum ParsedType: CustomStringConvertible {
    enum Error: Swift.Error, CustomStringConvertible {
        case unknownParameterType(String, syntaxType: Any.Type)
        case failedToParse(Any.Type)

        var description: String {
            switch self {
            case let .unknownParameterType(type, syntaxType):
                "unknownParameterType(\(type), syntaxType: \(syntaxType))"
            case let .failedToParse(type):
                "failedToParse(\(type))"
            }
        }
    }

    case plain(TokenSyntax)
    case optional(of: Self)
    case array(of: Self)
    case dictionary(key: Self, value: Self)
    case member(base: Self, extension: TokenSyntax)
    case metatype(base: Self)
    case unknownGeneric(TokenSyntax, arguments: [Self])

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

    public var description: String {
        switch self {
        case let .plain(type):
            "\(type)"
        case let .optional(type):
            "\(type)?"
        case let .array(type):
            "[\(type)]"
        case let .dictionary(key, value):
            "[\(key): \(value)]"
        case let .member(base, `extension`):
            "\(base.description).\(`extension`)"
        case let .metatype(base):
            "\(base.description).Type"
        case let .unknownGeneric(name, arguments: arguments):
            "\(name)<\(arguments.map(\.description).joined(separator: ", "))>"
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
                    self = .unknownGeneric(name, arguments: arguments)
                }
            } else {
                self = .plain(name)
            }
        } else if let type = syntax.as(OptionalTypeSyntax.self) {
            self = try .optional(of: Self(syntax: type.wrappedType))
        } else if let type = syntax.as(ArrayTypeSyntax.self) {
            self = try .array(of: Self(syntax: type.element))
        } else if let type = syntax.as(DictionaryTypeSyntax.self) {
            let key = try Self(syntax: type.key)
            let value = try Self(syntax: type.value)
            self = .dictionary(key: key, value: value)
        } else if let type = syntax.as(MemberTypeSyntax.self) {
            let kind = try Self(syntax: type.baseType)
            self = .member(base: kind, extension: type.name.trimmed)
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
