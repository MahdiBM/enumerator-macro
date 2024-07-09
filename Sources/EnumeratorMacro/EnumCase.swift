import SwiftDiagnostics
import SwiftSyntax
import Mustache

public struct EnumCase {

    public struct MustacheString {
        fileprivate var underlying: String

        public init(_ underlying: String) {
            self.underlying = underlying
        }
    }

    public struct MustacheArray<Element> {
        fileprivate let underlying: [Element]

        init(underlying: [Element]) {
            self.underlying = underlying
        }
    }

    public struct MustacheArrayOfOptionals<Element> {
        fileprivate let underlying: [Element?]

        init(underlying: [Element?]) {
            self.underlying = underlying
        }
    }

    public struct Parameter {
        public let name: MustacheString?
        public let type: MustacheString

        public init(name: String?, type: String) {
            self.name = name.map { .init($0) }
            self.type = .init(type)
        }
    }

    public struct Parameters {
        fileprivate let underlying: [Parameter]

        init(underlying: [Parameter]) {
            self.underlying = underlying
        }
    }

    public let name: MustacheString
    public let parameters: Parameters

    public init(from element: EnumCaseElementSyntax) throws {
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(underlying: parameters.map { parameter in
            Parameter(
                name: (parameter.secondName ?? parameter.firstName)?.trimmedDescription,
                type: parameter.type.trimmedDescription
            )
        })
    }
}

// MARK: - + MustacheArray

extension EnumCase.MustacheArray: Sequence, MustacheSequence {
    public func makeIterator() -> Array<Element>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EnumCase.MustacheArray: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

//extension EnumCase.MustacheArray: CustomReflectable {
//    public var customMirror: Mirror {
//        Mirror(reflecting: self.underlying)
//    }
//}

extension EnumCase.MustacheArray: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .map { String(describing: $0) }
                    .joined(separator: ", ")
                let string = EnumCase.MustacheString(joined)
                return string
            case "joinedWithParenthesis":
                if self.underlying.isEmpty {
                    return ""
                } else {
                    let joined = self.underlying
                        .map { String(describing: $0) }
                        .joined(separator: "T ")
                    let string = EnumCase.MustacheString("(\(joined))")
                    return string
                }
            default:
                return nil
            }
        }
    }
}

// MARK: - + MustacheArrayOfOptionals

extension EnumCase.MustacheArrayOfOptionals: Sequence, MustacheSequence {
    public func makeIterator() -> Array<Element?>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EnumCase.MustacheArrayOfOptionals: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

//extension EnumCase.MustacheArrayOfOptionals: CustomReflectable {
//    public var customMirror: Mirror {
//        Mirror(reflecting: self.underlying)
//    }
//}

extension EnumCase.MustacheArrayOfOptionals: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .enumerated()
                    .map { $1.map { String(describing: $0) } ?? "_unnamed_\($0)" }
                    .joined(separator: ", ")
                let string = EnumCase.MustacheString(joined)
                return string
            case "joinedWithParenthesis":
                if self.underlying.isEmpty {
                    return ""
                } else {
                    let joined = self.underlying
                        .enumerated()
                        .map { $1.map { String(describing: $0) } ?? "_unnamed_\($0)" }
                        .joined(separator: "T ")
                    let string = EnumCase.MustacheString("(\(joined))")
                    return string
                }
            default:
                return nil
            }
        }
    }
}

// MARK: - + Parameters

extension EnumCase.Parameters: Sequence, MustacheSequence {
    public func makeIterator() -> Array<EnumCase.Parameter>.Iterator {
        self.underlying.makeIterator()
    }
}

//extension EnumCase.Parameters: CustomReflectable {
//    public var customMirror: Mirror {
//        Mirror(reflecting: self.underlying)
//    }
//}

extension EnumCase.Parameters: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .map(\.name)
                    .enumerated()
                    .map { $1?.underlying ?? "_unnamed_\($0)" }
                    .joined(separator: ", ")
                let string = EnumCase.MustacheString(joined)
                return string
            case "joinedWithParenthesis":
                let names = self.underlying.map(\.name)
                if names.isEmpty {
                    return EnumCase.MustacheString("")
                } else {
                    let joined = names
                        .enumerated()
                        .map { $1?.underlying ?? "_unnamed_\($0)" }
                        .joined(separator: "T ")
                    let string = EnumCase.MustacheString("(\(joined))")
                    return string
                }
            case "namesWithTypes":
                let namesWithTypes = self
                    .map { ($0.name.map { "\($0): " } ?? "") + $0.type }
                let array = EnumCase.MustacheArray(underlying: namesWithTypes)
                return array
            case "names":
                let names = self.map(\.name)
                let array = EnumCase.MustacheArrayOfOptionals(underlying: names)
                return array
            case "types":
                let types = self.map(\.type)
                let array = EnumCase.MustacheArray(underlying: types)
                return array
            default:
                return nil
            }
        }
    }
}

extension EnumCase.Parameters: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

// MARK: - + MustacheString

extension EnumCase.MustacheString: CustomStringConvertible {
    public var description: String {
        self.underlying.description
    }
}

//extension EnumCase.MustacheString: CustomReflectable {
//    public var customMirror: Mirror {
//        self.underlying.customMirror
//    }
//}

extension EnumCase.MustacheString: MustacheTransformable {
    public func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "snakeCased":
                return EnumCase.MustacheString(
                    self.underlying.convertedToSnakeCase()
                )
            default:
                return nil
            }
        }
    }
}

extension EnumCase.MustacheString: StringProtocol {

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

// MARK: - + String

private extension String {
    /// Returns a new string with the camel-case-based words of this string
    /// split by the specified separator.
    ///
    /// Examples:
    ///
    ///     "myProperty".convertedToSnakeCase()
    ///     // my_property
    ///     "myURLProperty".convertedToSnakeCase()
    ///     // my_url_property
    ///     "myURLProperty".convertedToSnakeCase(separator: "-")
    ///     // my-url-property
    func convertedToSnakeCase(separator: Character = "_") -> String {
        guard !isEmpty else { return "" }
        var result = ""
        // Whether we should append a separator when we see a uppercase character.
        var separateOnUppercase = true
        for index in indices {
            let nextIndex = self.index(after: index)
            let character = self[index]
            if character.isUppercase {
                if separateOnUppercase, !result.isEmpty {
                    // Append the separator.
                    result += "\(separator)"
                }
                // If the next character is uppercase and the next-next character is lowercase, like "L" in "URLSession", we should separate words.
                separateOnUppercase = nextIndex < endIndex && self[nextIndex].isUppercase && self.index(after: nextIndex) < endIndex && self[self.index(after: nextIndex)].isLowercase
            } else {
                // If the character is `separator`, we do not want to append another separator when we see the next uppercase character.
                separateOnUppercase = character != separator
            }
            // Append the lowercased character.
            result += character.lowercased()
        }
        return result
    }
}

private func convertToCustomTypesIfPossible(_ value: Any) -> Any {
    switch value {
    case let string as any StringProtocol:
        return EnumCase.MustacheString(string.description)
    case let array as Array<EnumCase.Parameter>:
        return EnumCase.Parameters(underlying: array)
    case let seq as any Sequence:
        return EnumCase.MustacheArray<Any>(underlying: seq.map { $0 })
        /// TODO: Handle arrays of optionals
    default:
        return value
    }
}
