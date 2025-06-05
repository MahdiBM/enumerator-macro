import Mustache

enum EOptional<Wrapped> {
    case none
    case some(Wrapped)

    init(_ optional: Wrapped?) {
        switch optional {
        case .none:
            self = .none
        case let .some(value):
            self = .some(value)
        }
    }

    func toOptional() -> Wrapped? {
        switch self {
        case .none:
            return .none
        case let .some(value):
            return .some(value)
        }
    }

    func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> EOptional<U> {
        switch self {
        case .none:
            return .none
        case .some(let wrapped):
            return .some(
                try transform(wrapped)
            )
        }
    }

    func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> EOptional<U> {
        switch self {
        case .none:
            return .none
        case .some(let wrapped):
            let transformed = try transform(wrapped)
            switch transformed {
            case let .some(value):
                return .some(value)
            case .none:
                return .none
            }
        }
    }

    static func ?? (lhs: Self, rhs: Wrapped) -> Wrapped {
        switch lhs {
        case .none:
            return rhs
        case .some(let wrapped):
            return wrapped
        }
    }
}

extension EOptional: CustomStringConvertible {
    var description: String {
        switch self {
        case .none:
            return ""
        case .some(let wrapped):
            return String(describing: wrapped)
        }
    }
}

extension EOptional: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "Optional<\(bestEffortTypeName(Wrapped.self))>"
    }
}

extension EOptional: Equatable where Wrapped: Equatable {
    static func < (lhs: EOptional<Wrapped>, rhs: EOptional<Wrapped>) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs == rhs
        case (.some, .none):
            return false
        case (.none, .some):
            return false
        case (.none, .none):
            return true
        }
    }
}

extension EOptional: Comparable where Wrapped: Comparable {
    static func < (lhs: EOptional<Wrapped>, rhs: EOptional<Wrapped>) -> Bool {
        switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs < rhs
        case (.some, .none):
            return false
        case (.none, .some):
            return true
        case (.none, .none):
            return false
        }
    }
}

extension EOptional: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch self {
        case .none:
            switch name {
            case "isEmpty":
                return true
            case "bool":
                return false
            case "exists":
                return false
            default:
                RenderingContext.current.addOrReplaceFunctionDiagnostic(
                    .invalidTransform(
                        transform: name,
                        normalizedTypeName: Self.normalizedTypeName
                    )
                )
                return nil
            }
        case let .some(value):
            switch name {
            case "exists":
                return true
            default:
                if let value = value as? (any EMustacheTransformable) {
                    /// The underlying type is in charge of adding a diagnostic, if needed.
                    return value.transform(name)
                } else {
                    RenderingContext.current.addOrReplaceFunctionDiagnostic(
                        .invalidTransform(
                            transform: name,
                            normalizedTypeName: Self.normalizedTypeName
                        )
                    )
                    return nil
                }
            }
        }
    }
}
