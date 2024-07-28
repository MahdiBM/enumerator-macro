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
            let names = self.map(\.name)
            let array = EArray(underlying: names)
            return array
        case "types":
            let types = self.map(\.type)
            let array = EArray(underlying: types)
            return array
        case "namesAndTypes":
            let namesAndTypes = self.map { element in
                element.name + ": " + element.type
            }
            let array = EArray(underlying: namesAndTypes)
            return array
        case "tupleValue":
            if self.underlying.underlying.count == 1 {
                return EArray(underlying: [underlying.underlying[0].type])
            } else {
                let namesAndTypes = self.map { element in
                    element.name + ": " + element.type
                }
                let array = EArray(underlying: namesAndTypes)
                return array
            }
        case "sorted":
            var array = self.underlying.underlying
            if array.isEmpty { return self }
            array[0].isFirst = false
            array[array.count - 1].isLast = false
            array.sort()
            array[0].isFirst = true
            array[array.count - 1].isLast = true
            return Self.init(underlying: array)
        default:
            /// The underlying type is in charge of adding a diagnostic, if needed.
            return self.underlying.transform(name)
        }
    }
}
