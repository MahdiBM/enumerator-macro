import Mustache

public struct MString {
    var underlying: String

    public init(_ underlying: String) {
        self.underlying = underlying
    }
}

extension MString: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

extension MString: CustomReflectable {
    public var customMirror: Mirror {
        self.underlying.customMirror
    }
}

extension MString: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
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
    public typealias Index = String.Index
    public typealias UTF8View = String.UTF8View
    public typealias UTF16View = String.UTF16View
    public typealias UnicodeScalarView = String.UnicodeScalarView
    public typealias SubSequence = String.SubSequence

    public var utf8: String.UTF8View {
        self.underlying.utf8
    }

    public var utf16: String.UTF16View {
        self.underlying.utf16
    }

    public var unicodeScalars: String.UnicodeScalarView {
        self.underlying.unicodeScalars
    }

    public subscript(position: String.Index) -> Character {
        _read {
            yield self.underlying[position]
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        self.underlying[bounds]
    }

    public func lowercased() -> String {
        self.underlying.lowercased()
    }

    public func uppercased() -> String {
        self.underlying.uppercased()
    }

    public func hasPrefix(_ prefix: String) -> Bool {
        self.underlying.hasPrefix(prefix)
    }

    public func hasSuffix(_ suffix: String) -> Bool {
        self.underlying.hasSuffix(suffix)
    }

    public init<C, Encoding>(
        decoding codeUnits: C,
        as sourceEncoding: Encoding.Type = Encoding.self
    ) where C : Collection, Encoding : _UnicodeEncoding, C.Element == Encoding.CodeUnit {
        self.init(String(
            decoding: codeUnits,
            as: sourceEncoding
        ))
    }

    public init(cString nullTerminatedUTF8: UnsafePointer<CChar>) {
        self.init(String(cString: nullTerminatedUTF8))
    }

    public init<Encoding>(
        decodingCString nullTerminatedCodeUnits: UnsafePointer<Encoding.CodeUnit>,
        as sourceEncoding: Encoding.Type = Encoding.self
    ) where Encoding : _UnicodeEncoding {
        self.init(String(
            decodingCString: nullTerminatedCodeUnits,
            as: sourceEncoding
        ))
    }

    public func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result {
        try self.underlying.withCString(body)
    }

    public func withCString<Result, Encoding>(
        encodedAs targetEncoding: Encoding.Type = Encoding.self,
        _ body: (UnsafePointer<Encoding.CodeUnit>) throws -> Result
    ) rethrows -> Result where Encoding : _UnicodeEncoding {
        try self.underlying.withCString(encodedAs: targetEncoding, body)
    }

    public func index(before i: String.Index) -> String.Index {
        self.underlying.index(before: i)
    }

    public func index(after i: String.Index) -> String.Index {
        self.underlying.index(after: i)
    }

    public var startIndex: String.Index {
        self.underlying.startIndex
    }

    public var endIndex: String.Index {
        self.underlying.endIndex
    }

    public mutating func write(_ string: String) {
        self.underlying.write(string)
    }

    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        self.underlying.write(to: &target)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}
