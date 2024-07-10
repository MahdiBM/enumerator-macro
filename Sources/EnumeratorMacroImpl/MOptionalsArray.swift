import Mustache

struct MOptionalsArray<Element> {
    fileprivate let underlying: [Element?]

    init(underlying: [Element?]) {
        self.underlying = underlying
    }
}

extension MOptionalsArray: Sequence, MustacheSequence {
    func makeIterator() -> Array<Element?>.Iterator {
        self.underlying.makeIterator()
    }
}

extension MOptionalsArray: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension MOptionalsArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension MOptionalsArray: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .enumerated()
                    .map { $1.map { String(describing: $0) } ?? "_unnamed_\($0)" }
                    .joined(separator: ", ")
                let string = MString(joined)
                return string
            default:
                return nil
            }
        }
    }
}
