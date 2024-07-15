import Mustache

enum EOptional<Wrapped> {
    case none
    case some(Wrapped)

    init(_ optional: Optional<Wrapped>) {
        switch optional {
        case .none:
            self = .none
        case let .some(value):
            self = .some(value)
        }
    }

    func toOptional() -> Optional<Wrapped> {
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

extension EOptional: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch self {
        case .none:
            switch name {
            case "bool":
                return false
            default:
                return nil
            }
        case let .some(value):
            if let value = value as? MustacheTransformable {
                return value.transform(name)
            } else {
                return nil
            }
        }
    }
}
