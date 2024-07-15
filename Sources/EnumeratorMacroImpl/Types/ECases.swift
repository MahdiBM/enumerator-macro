import Mustache
import SwiftSyntax

struct ECases {
    fileprivate let underlying: EArray<ECase>

    init(elements: [EnumCaseElementSyntax]) throws {
        self.underlying = .init(
            underlying: try elements.map(ECase.init(from:))
        )
    }
}

extension ECases: CustomStringConvertible {
    var description: String {
        self.underlying.description
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
            switch name {
            case "filterNoParams":
                return self.filter(\.parameters.underlying.underlying.isEmpty)
            case "filterWithParams":
                return self.filter({ !$0.parameters.underlying.underlying.isEmpty })
            default:
                return nil
            }
        }
    }
}
