import Mustache

struct EParameters {
    let underlying: EArray<EParameter>

    init(underlying: [EParameter]) {
        self.underlying = .init(underlying: underlying)
    }
}

extension EParameters: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EParameters: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Parameter]"
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

extension EParameters: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "names":
            let names = self
                .enumerated()
                .map { idx, element in
                    element.name ?? "param\(idx + 1)"
                }
            let array = EArray(underlying: names)
            return array
        case "types":
            let types = self.map(\.type)
            let array = EArray(underlying: types)
            return array
//        case "isOptionals":
//            let types = self.map(\.isOptional)
//            let array = EArray(underlying: types)
//            return array
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
            /// The underlying type is in charge of adding a diagnostic, if needed.
            return self.underlying.transform(name)
        }
    }
}
