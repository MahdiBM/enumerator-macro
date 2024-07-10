import Mustache

struct EArray<Element> {
    fileprivate let underlying: [Element]

    init(underlying: [Element]) {
        self.underlying = underlying
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
            default:
                return nil
            }
        }
    }
}
