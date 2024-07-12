import Mustache

struct EString {
    var underlying: String

    init(_ underlying: String) {
        self.underlying = underlying
    }
}

extension EString: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EString: CustomReflectable {
    var customMirror: Mirror {
        self.underlying.customMirror
    }
}

extension EString: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "firstCapitalized":
                if self.isEmpty {
                    return self
                }
                let modified = self[self.startIndex].uppercased() + self[self.index(after: self.startIndex)...]
                return EString(modified)
            case "snakeCased":
                return self.convertedToSnakeCase()
            case "camelCased":
                return self.convertToCamelCase()
            case "withParens":
                return self.isEmpty ? self : "(\(self))"
            default:
                return nil
            }
        }
    }
}

extension EString: StringProtocol {
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

extension EString: RangeReplaceableCollection {
    init() {
        self.underlying = ""
    }

    mutating func replaceSubrange<C>(
        _ subrange: Range<String.Index>,
        with newElements: C
    ) where C : Collection, Character == C.Element {
        self.underlying.replaceSubrange(subrange, with: newElements)
    }
}

private extension StringProtocol where Self: RangeReplaceableCollection {
    /// Returns a new string with the camel-case-based words of this string
    /// split by the specified separator.
    ///
    /// Examples:
    ///
    ///     "myProperty".convertedToSnakeCase()
    ///     // my_property
    ///     "myURLProperty".convertedToSnakeCase()
    ///     // my_url_property
    func convertedToSnakeCase() -> Self {
        guard !isEmpty else { return "" }
        var result: Self = ""
        // Whether we should append a separator when we see a uppercase character.
        var separateOnUppercase = true
        for index in indices {
            let nextIndex = self.index(after: index)
            let character = self[index]
            if character.isUppercase {
                if separateOnUppercase, !result.isEmpty {
                    // Append the separator.
                    result += "_"
                }
                // If the next character is uppercase and the next-next character is lowercase, like "L" in "URLSession", we should separate words.
                separateOnUppercase = nextIndex < endIndex && self[nextIndex].isUppercase && self.index(after: nextIndex) < endIndex && self[self.index(after: nextIndex)].isLowercase
            } else {
                // If the character is `separator`, we do not want to append another separator when we see the next uppercase character.
                separateOnUppercase = character != "_"
            }
            // Append the lowercased character.
            result += character.lowercased()
        }
        return result
    }

    func convertToCamelCase() -> Self {
        guard !self.isEmpty else { return self }

        // Find the first non-underscore character
        guard let firstNonUnderscore = self.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return self
        }

        // Find the last non-underscore character
        var lastNonUnderscore = self.index(before: self.endIndex)
        while lastNonUnderscore > firstNonUnderscore && self[lastNonUnderscore] == "_" {
            self.formIndex(before: &lastNonUnderscore)
        }

        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = self.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = self.index(after: lastNonUnderscore)..<self.endIndex

        let components = self[keyRange].split(separator: "_")
        let joinedString: Self
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = Self(self[keyRange])
        } else {
            joinedString = Self(([components[0].lowercased()] + components[1...].map(\.capitalized)).joined())
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result: Self
        if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
            result = joinedString
        } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
            // Both leading and trailing underscores
            result = Self(self[leadingUnderscoreRange]) + joinedString + Self(self[trailingUnderscoreRange])
        } else if (!leadingUnderscoreRange.isEmpty) {
            // Just leading
            result = Self(self[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + Self(self[trailingUnderscoreRange])
        }
        return result
    }
}
