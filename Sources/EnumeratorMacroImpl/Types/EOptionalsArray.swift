import Mustache

struct EOptionalsArray<Element> {
    fileprivate let underlying: [EOptional<Element>]

    init(underlying: [Element?]) {
        self.underlying = underlying.map(EOptional.init)
    }

    init(underlying: [EOptional<Element>]) {
        self.underlying = underlying
    }

    @available(*, unavailable, message: "Unwrap the optionals-array first")
    init(underlying: EOptionalsArray<Element>) {
        fatalError()
    }
}

extension EOptionalsArray: Sequence, MustacheSequence {
    func makeIterator() -> Array<EOptional<Element>>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EOptionalsArray: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EOptionalsArray: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Optional<\(bestEffortTypeName(Element.self))>]"
    }
}

extension EOptionalsArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EOptionalsArray: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "first":
            return self.underlying.first
        case "last":
            return self.underlying.last
        case "reversed":
            return EOptionalsArray(underlying: self.reversed().map { $0 })
        case "count":
            return self.underlying.count
        case "isEmpty":
            return self.underlying.isEmpty
        case "joined":
            let joined = self.underlying
                .enumerated()
                .map { $1.map { String(describing: $0) } ?? "param\($0 + 1)" }
                .joined(separator: ", ")
            let string = EString(joined)
            return string
        case "keyValues":
            let split: [EKeyValue] = self.underlying
                .compactMap { $0.toOptional().map { String(describing: $0) } }
                .compactMap(EKeyValue.init(from:))
            return EArray<EKeyValue>(underlying: split)
        default:
            if let keyValues = self as? EOptionalsArray<EKeyValue> {
                /// Don't throw even if the key doesn't exist.
                switch keyValues.underlying.first(where: { $0.toOptional()?.key.underlying == name }) {
                case let .some(wrapped):
                    return wrapped.map(\.value)
                case nil:
                    return EOptional<EString>.none
                }
            }
            if let comparable = self as? EComparableSequence {
                /// The underlying type is in charge of adding a diagnostic, if needed.
                return comparable.comparableTransform(name)
            }
            RenderingContext.current.addOrReplaceDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}

extension EOptionalsArray: EComparableSequence where Element: Comparable {
    func comparableTransform(_ name: String) -> Any? {
        switch name {
        case "sorted":
            return EOptionalsArray(underlying: self.underlying.sorted())
        default:
            RenderingContext.current.addOrReplaceDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}
