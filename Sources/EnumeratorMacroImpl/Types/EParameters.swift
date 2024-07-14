import Mustache

struct EParameters {
    fileprivate let underlying: EArray<EParameter>

    init(underlying: [EParameter]) {
        self.underlying = .init(underlying: underlying)
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
            case "names":
                let names = self.map(\.name)
                let array = EOptionalsArray(underlying: names)
                return array
            case "types":
                let types = self.map(\.type)
                let array = EArray(underlying: types)
                return array
            case "namesAndTypes":
                let namesAndTypes = self
                    .enumerated()
                    .map { idx, element in
                        (element.name ?? "param\(idx + 1)") + ": " + element.type
                    }
                let array = EArray(underlying: namesAndTypes)
                return array
            case "tupleValue":
                if self.underlying.underlying.count == 1 {
                    return EArray(underlying: [underlying.underlying[0].type])
                } else {
                    let namesAndTypes = self
                        .enumerated()
                        .map { idx, element in
                            (element.name ?? "param\(idx + 1)") + ": " + element.type
                        }
                    let array = EArray(underlying: namesAndTypes)
                    return array
                }
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
