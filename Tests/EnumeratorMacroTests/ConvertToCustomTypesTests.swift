@testable import EnumeratorMacroImpl
import XCTest

final class ConvertToCustomTypesTests: XCTestCase {
    func testConvertsToEString() {
        let value = ""
        let converted = convertToCustomTypesIfPossible(value)
        let convertedType = type(of: converted)
        XCTAssertTrue(convertedType is EString.Type, "\(converted); \(convertedType)")
    }

    func testConvertsToEParameters() {
        let value: [EParameter] = [.init(name: nil, type: "")]
        let converted = convertToCustomTypesIfPossible(value)
        let convertedType = type(of: converted)
        XCTAssertTrue(convertedType is EParameters.Type, "\(converted); \(convertedType)")
    }

    func testConvertsToEArray() throws {
        let value: [Int] = [1]
        let converted = convertToCustomTypesIfPossible(value)
        let convertedType = type(of: converted)
        XCTAssertTrue(convertedType is EArray<Any>.Type, "\(converted); \(convertedType)")

        let array = try XCTUnwrap(converted as? EArray<Any>)
        var iterator = array.makeIterator()
        let element = try XCTUnwrap(iterator.next())
        let elementType = type(of: element)
        XCTAssertTrue(elementType is Int.Type, "\(element); \(elementType)")
    }

    func testConvertsToEArrayAndRecursesForElements() throws {
        let value: [String] = [""]
        let converted = convertToCustomTypesIfPossible(value)
        let convertedType = type(of: converted)
        XCTAssertTrue(convertedType is EArray<Any>.Type, "\(converted); \(convertedType)")

        let array = try XCTUnwrap(converted as? EArray<Any>)
        var iterator = array.makeIterator()
        let element = try XCTUnwrap(iterator.next())
        let elementType = type(of: element)
        XCTAssertTrue(elementType is EString.Type, "\(element); \(elementType)")
    }

//    func testConvertsToEOptionalsArrayAndRecursesForElements() throws {
//        let value: [String?] = [""]
//        let converted = convertToCustomTypesIfPossible(value)
//        let convertedType = type(of: converted)
//        XCTAssertTrue(convertedType is EOptionalsArray<Any>.Type, "\(converted); \(convertedType)")
//
//        let array = try XCTUnwrap(converted as? EArray<Any>)
//        var iterator = array.makeIterator()
//        let element = try XCTUnwrap(iterator.next())
//        let elementType = type(of: element)
//        XCTAssertTrue(elementType is EString.Type, "\(element); \(elementType)")
//    }
}
