/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

/// Borrowed from https://github.com/swiftlang/swift-tools-support-core/Sources/TSCBasic/ByteString.swift

import Foundation

/// A `ByteString` represents a sequence of bytes.
///
/// This struct provides useful operations for working with buffers of
/// bytes. Conceptually it is just a contiguous array of bytes (UInt8), but it
/// contains methods and default behavior suitable for common operations done
/// using bytes strings.
///
/// This struct *is not* intended to be used for significant mutation of byte
/// strings, we wish to retain the flexibility to micro-optimize the memory
/// allocation of the storage (for example, by inlining the storage for small
/// strings or and by eliminating wasted space in growable arrays). For
/// construction of byte arrays, clients should use the `WritableByteStream` class
/// and then convert to a `ByteString` when complete.
struct ByteString: ExpressibleByArrayLiteral, Hashable, Sendable {
    /// The buffer contents.
    @usableFromInline
    internal var _bytes: [UInt8]

    /// Create an empty byte string.
    @inlinable
    init() {
        _bytes = []
    }

    /// Create a byte string from a byte array literal.
    @inlinable
    init(arrayLiteral contents: UInt8...) {
        _bytes = contents
    }

    /// Create a byte string from an array of bytes.
    @inlinable
    init(_ contents: [UInt8]) {
        _bytes = contents
    }

    /// Create a byte string from an array slice.
    @inlinable
    init(_ contents: ArraySlice<UInt8>) {
        _bytes = Array(contents)
    }

    /// Create a byte string from an byte buffer.
    @inlinable
    init<S: Sequence> (_ contents: S) where S.Iterator.Element == UInt8 {
        _bytes = [UInt8](contents)
    }

    /// Create a byte string from the UTF8 encoding of a string.
    @inlinable
    init(encodingAsUTF8 string: String) {
        _bytes = [UInt8](string.utf8)
    }

    /// Access the byte string contents as an array.
    @inlinable
    var contents: [UInt8] {
        return _bytes
    }

    /// Return the byte string size.
    @inlinable
    var count: Int {
        return _bytes.count
    }

    /// Gives a non-escaping closure temporary access to an immutable `Data` instance wrapping the `ByteString` without
    /// copying any memory around.
    ///
    /// - Parameters:
    ///   - closure: The closure that will have access to a `Data` instance for the duration of its lifetime.
    @inlinable
    func withData<T>(_ closure: (Data) throws -> T) rethrows -> T {
        return try _bytes.withUnsafeBytes { pointer -> T in
            let mutatingPointer = UnsafeMutableRawPointer(mutating: pointer.baseAddress!)
            let data = Data(bytesNoCopy: mutatingPointer, count: pointer.count, deallocator: .none)
            return try closure(data)
        }
    }

    /// Returns a `String` lowercase hexadecimal representation of the contents of the `ByteString`.
    @inlinable
    var hexadecimalRepresentation: String {
        _bytes.reduce("") {
            var str = String($1, radix: 16)
            // The above method does not do zero padding.
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + str
        }
    }

    /// Returns a `String` lowercase hexadecimal representation of the contents of the `ByteString`.
    @inlinable
    var decimalRepresentation: String {
        _bytes.reduce("") {
            var str = String($1, radix: 10)
            // The above method does not do zero padding.
            if str.count == 1 {
                str = "0" + str
            }
            return $0 + str
        }
    }
}

/// Conform to CustomDebugStringConvertible.
extension ByteString: CustomStringConvertible {
    /// Return the string decoded as a UTF8 sequence, or traps if not possible.
    var description: String {
        return cString
    }

    /// Return the string decoded as a UTF8 sequence, if possible.
    @available(*, deprecated, message: "Mahdi: Just so it doesn't emit a warning")
    @inlinable
    var validDescription: String? {
        // FIXME: This is very inefficient, we need a way to pass a buffer. It
        // is also wrong if the string contains embedded '\0' characters.
        let tmp = _bytes + [UInt8(0)]
        return tmp.withUnsafeBufferPointer { ptr in
            return String(validatingUTF8: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
        }
    }

    /// Return the string decoded as a UTF8 sequence, substituting replacement
    /// characters for ill-formed UTF8 sequences.
    @inlinable
    var cString: String {
        return String(decoding: _bytes, as: Unicode.UTF8.self)
    }

    @available(*, deprecated, message: "use description or validDescription instead")
    var asString: String? {
        return validDescription
    }
}

/// StringLiteralConvertable conformance for a ByteString.
extension ByteString: ExpressibleByStringLiteral {
    typealias UnicodeScalarLiteralType = StringLiteralType
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
    init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
    init(stringLiteral value: StringLiteralType) {
        _bytes = [UInt8](value.utf8)
    }
}
