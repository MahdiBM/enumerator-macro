import Mustache

struct EParameters {
    fileprivate let underlying: [EParameter]

    init(underlying: [EParameter]) {
        self.underlying = underlying
    }
}

extension EParameters: Sequence, MustacheSequence {
    func makeIterator() -> Array<EParameter>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EParameters: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EParameters: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .map(\.name)
                    .enumerated()
                    .map { $1?.underlying ?? "_param\($0)" }
                    .joined(separator: ", ")
                let string = EString(joined)
                return string
            case "namesWithTypes":
                let namesWithTypes = self
                    .map { ($0.name.map { "\($0): " } ?? "") + $0.type }
                let array = EArray(underlying: namesWithTypes)
                return array
            case "names":
                let names = self.map(\.name)
                let array = EOptionalsArray(underlying: names)
                return array
            case "types":
                let types = self.map(\.type)
                let array = EArray(underlying: types)
                return array
            default:
                return nil
            }
        }
    }
}

extension EParameters: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}
