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

extension EArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EArray: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
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
                    let value = keyValues.first(where: { $0.key == name })?.value
                    return EOptional(value)
                }
                return nil
            }
        }
    }
}
