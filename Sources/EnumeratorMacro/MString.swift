import Mustache

struct MString {
    var underlying: String

    init(_ underlying: String) {
        self.underlying = underlying
    }
}

extension MString: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension MString: CustomReflectable {
    var customMirror: Mirror {
        self.underlying.customMirror
    }
}

extension MString: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "snakeCased":
                return MString(
                    self.underlying.convertedToSnakeCase()
                )
            default:
                return nil
            }
        }
    }
}

extension MString: StringProtocol {
    typealias Index = String.Index
    typealias UTF8View = String.UTF8View
    typealias UTF16View = String.UTF16View
    typealias UnicodeScalarView = String.UnicodeScalarView
    typealias SubSequence = String.SubSequence

    var utf8: String.UTF8View {
        self.underlying.utf8
    }

    var utf16: String.UTF16View {
        self.underlying.utf16
    }

    var unicodeScalars: String.UnicodeScalarView {
        self.underlying.unicodeScalars
    }

    subscript(position: String.Index) -> Character {
        _read {
            yield self.underlying[position]
        }
    }

    subscript(bounds: Range<Index>) -> SubSequence {
        self.underlying[bounds]
    }

    func lowercased() -> String {
        self.underlying.lowercased()
    }

    func uppercased() -> String {
        self.underlying.uppercased()
    }

    func hasPrefix(_ prefix: String) -> Bool {
        self.underlying.hasPrefix(prefix)
    }

    func hasSuffix(_ suffix: String) -> Bool {
        self.underlying.hasSuffix(suffix)
    }

    init<C, Encoding>(
        decoding codeUnits: C,
        as sourceEncoding: Encoding.Type = Encoding.self
    ) where C : Collection, Encoding : _UnicodeEncoding, C.Element == Encoding.CodeUnit {
        self.init(String(
            decoding: codeUnits,
            as: sourceEncoding
        ))
    }

    init(cString nullTerminatedUTF8: UnsafePointer<CChar>) {
        self.init(String(cString: nullTerminatedUTF8))
    }

    init<Encoding>(
        decodingCString nullTerminatedCodeUnits: UnsafePointer<Encoding.CodeUnit>,
        as sourceEncoding: Encoding.Type = Encoding.self
    ) where Encoding : _UnicodeEncoding {
        self.init(String(
            decodingCString: nullTerminatedCodeUnits,
            as: sourceEncoding
        ))
    }

    func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result {
        try self.underlying.withCString(body)
    }

    func withCString<Result, Encoding>(
        encodedAs targetEncoding: Encoding.Type = Encoding.self,
        _ body: (UnsafePointer<Encoding.CodeUnit>) throws -> Result
    ) rethrows -> Result where Encoding : _UnicodeEncoding {
        try self.underlying.withCString(encodedAs: targetEncoding, body)
    }

    func index(before i: String.Index) -> String.Index {
        self.underlying.index(before: i)
    }

    func index(after i: String.Index) -> String.Index {
        self.underlying.index(after: i)
    }

    var startIndex: String.Index {
        self.underlying.startIndex
    }

    var endIndex: String.Index {
        self.underlying.endIndex
    }

    mutating func write(_ string: String) {
        self.underlying.write(string)
    }

    func write<Target>(to target: inout Target) where Target : TextOutputStream {
        self.underlying.write(to: &target)
    }

    init(stringLiteral value: String) {
        self.init(value)
    }
}
