import Mustache

struct EOptionalsArray<Element> {
    fileprivate let underlying: [Element?]

    init(underlying: [Element?]) {
        self.underlying = underlying
    }

    @available(*, unavailable, message: "Unwrap the optionals-array first")
    init(underlying: EOptionalsArray<Element>) {
        fatalError()
    }
}

extension EOptionalsArray: Sequence, MustacheSequence {
    func makeIterator() -> Array<Element?>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EOptionalsArray: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EOptionalsArray: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EOptionalsArray: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .enumerated()
                    .map { $1.map { String(describing: $0) } ?? "param\($0 + 1)" }
                    .joined(separator: ", ")
                let string = EString(joined)
                return string
            default:
                return nil
            }
        }
    }
}
