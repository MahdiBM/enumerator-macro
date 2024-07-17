import Mustache
import SwiftSyntax

struct ECases {
    fileprivate let underlying: EArray<ECase>

    init(elements: [EnumCaseElementSyntax]) throws {
        self.underlying = .init(
            underlying: try elements.enumerated().map { idx, element in
                try ECase(index: idx, from: element)
            }
        )
    }
}

extension ECases: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension ECases: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Case]"
    }
}

extension ECases: Sequence, MustacheSequence {
    func makeIterator() -> Array<ECase>.Iterator {
        self.underlying.makeIterator()
    }
}

extension ECases: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension ECases: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "filterNoParams":
            return self.filter(\.parameters.underlying.underlying.isEmpty)
        case "filterWithParams":
            return self.filter({ !$0.parameters.underlying.underlying.isEmpty })
        default:
            if let transformed = self.underlying.transform(name) {
                return transformed
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
