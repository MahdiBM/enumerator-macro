import Mustache
import Foundation

struct EArray<Element> {
    let underlying: [Element]

    init(underlying: [Element]) {
        self.underlying = underlying
    }

    @available(*, unavailable, message: "Unwrap the array first")
    init(underlying: EArray<Element>) {
        fatalError()
    }
}

extension EArray: Sequence, MustacheSequence {
    func makeIterator() -> Array<Element>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EArray: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EArray: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[\(bestEffortTypeName(Element.self))]"
    }
}

extension EArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EArray: EMustacheTransformable {
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
                .map { String(describing: $0) }
                .joined(separator: ", ")
            let string = EString(joined)
            return string
        case "keyValues":
            let split: [EKeyValue] = self.underlying
                .map { String(describing: $0) }
                .compactMap { string -> EKeyValue? in
                    let split = string.split(
                        separator: ":",
                        maxSplits: 1
                    ).map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    guard split.count > 0 else {
                        return nil
                    }
                    return EKeyValue(
                        key: EString(split[0]),
                        value: EString(split.count > 1 ? split[1] : "")
                    )
                }
            return EArray<EKeyValue>(underlying: split)
        default:
            if let keyValues = self as? EArray<EKeyValue> {
                /// Don't throw even if the key doesn't exist.
                return EOptional(
                    keyValues.underlying.first(where: { $0.key.underlying == name })?.value
                )
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

extension EArray: EComparableSequence where Element: Comparable {
    func comparableTransform(_ name: String) -> Any? {
        switch name {
        case "sorted":
            return EArray(underlying: self.underlying.sorted())
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
