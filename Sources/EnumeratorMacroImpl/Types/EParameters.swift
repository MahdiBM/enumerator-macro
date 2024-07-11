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
                    .map { $1?.underlying ?? "param\($0 + 1)" }
                    .joined(separator: ", ")
                let string = EString(joined)
                return string
            case "namesAndTypes":
                let namesAndTypes = self
                    .enumerated()
                    .map { idx, element in
                        (element.name ?? "param\(idx + 1)") + ": " + element.type
                    }
                let array = EArray(underlying: namesAndTypes)
                return array
            case "tupleValue":
                if self.underlying.count == 1 {
                    return EArray(underlying: [underlying[0].type])
                } else {
                    let namesAndTypes = self
                        .enumerated()
                        .map { idx, element in
                            (element.name ?? "param\(idx + 1)") + ": " + element.type
                        }
                    let array = EArray(underlying: namesAndTypes)
                    return array
                }
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
