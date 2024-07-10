import EnumeratorMacro
import EnumeratorMacroImpl
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class EnumeratorMacroTests: XCTestCase {
    func testCreatesCaseName() throws {
        assertMacroExpansion(
            #"""
            @Enumerator(
            """
            var caseName: String {
                switch self {
                {{#cases}}
                case .{{name}}:
                    "{{name}}"
                {{/cases}}
                }
            }
            """
            )
            enum TestEnum {
                case a
                case b
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a
                case b

                var caseName: String {
                    switch self {
                    case .a:
                        "a"
                    case .b:
                        "b"
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testCreatesACopyOfSelf() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum CopyOfSelf {
                {{#cases}}
                case {{name}}{{withParens(joined(namesWithTypes(parameters)))}}
                {{/cases}}
            }
            """)
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)

                enum CopyOfSelf {
                    case a(val1: String, val2: Int)
                    case b
                    case testCase(testValue: String)
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testCreatesDeclarationsForCaseChecking() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            {{#cases}}
            var is{{capitalized(name)}}: Bool {
                switch self {
                case .{{name}}:
                    return true
                default:
                    return false
                }
            }
            {{/cases}}
            """)
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)

                var isA: Bool {
                    switch self {
                    case .a:
                        return true
                    default:
                        return false
                    }
                }

                var isB: Bool {
                    switch self {
                    case .b:
                        return true
                    default:
                        return false
                    }
                }

                var isTestcase: Bool {
                    switch self {
                    case .testCase:
                        return true
                    default:
                        return false
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testCreatesSubtypeWithMultiMacroArguments() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum Subtype: String {
                {{#cases}}
                case {{name}}
                {{/cases}}
            }
            """,
            """
            var subtype: Subtype {
                switch self {
                {{#cases}}
                case .{{name}}:
                    .{{name}}
                {{/cases}}
                }
            }
            """)
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)

                enum Subtype: String {
                    case a
                    case b
                    case testCase
                }

                var subtype: Subtype {
                    switch self {
                    case .a:
                        .a
                    case .b:
                        .b
                    case .testCase:
                        .testCase
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testCreatesGetCaseValueFunctions() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            {{#cases}}
            {{^empty(parameters)}}
            func get{{capitalized(name)}}() -> ({{joined(namesWithTypes(parameters))}})? {
                switch self {
                case .{{name}}{{withParens(joined(namesWithTypes(parameters)))}}:
                    return {{withParens(joined(names(parameters)))}}
                default:
                    return nil
                }
            }
            {{/empty(parameters)}}
            {{/cases}}
            """)
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, val2: Int)
                case b
                case testCase(testValue: String)

                func getA() -> (val1: String, val2: Int)? {
                    switch self {
                    case .a(val1: String, val2: Int):
                        return (val1, val2)
                    default:
                        return nil
                    }
                }

                func getTestcase() -> (testValue: String)? {
                    switch self {
                    case .testCase(testValue: String):
                        return (testValue)
                    default:
                        return nil
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }
}
