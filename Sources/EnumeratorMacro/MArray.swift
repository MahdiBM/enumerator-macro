import Mustache

public struct MArray<Element> {
    fileprivate let underlying: [Element]

    init(underlying: [Element]) {
        self.underlying = underlying
    }
}

extension MArray: Sequence, MustacheSequence {
    public func makeIterator() -> Array<Element>.Iterator {
        self.underlying.makeIterator()
    }
}

extension MArray: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

extension MArray: CustomReflectable {
    public var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension MArray: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .map { String(describing: $0) }
                    .joined(separator: ", ")
                let string = MString(joined)
                return string
            case "joinedWithParenthesis":
                if self.underlying.isEmpty {
                    return ""
                } else {
                    let joined = self.underlying
                        .map { String(describing: $0) }
                        .joined(separator: ", ")
                    let string = MString("(\(joined))")
                    return string
                }
            default:
                return nil
            }
        }
    }
}
