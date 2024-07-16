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

extension ECases: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            RenderingContext.current.cleanDiagnostic()
            switch name {
            case "filterNoParams":
                return self.filter(\.parameters.underlying.underlying.isEmpty)
            case "filterWithParams":
                return self.filter({ !$0.parameters.underlying.underlying.isEmpty })
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
}
