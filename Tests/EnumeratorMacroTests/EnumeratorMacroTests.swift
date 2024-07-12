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
                case {{name}}{{withParens(joined(namesAndTypes(parameters)))}}
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
            var is{{firstCapitalized(name)}}: Bool {
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

                var isTestCase: Bool {
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
            func get{{firstCapitalized(name)}}() -> ({{joined(tupleValue(parameters))}})? {
                switch self {
                case let .{{name}}{{withParens(joined(names(parameters)))}}:
                    return {{withParens(joined(names(parameters)))}}
                default:
                    return nil
                }
            }
            {{/empty(parameters)}}
            {{/cases}}
            """)
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)

                func getA() -> (val1: String, param2: Int)? {
                    switch self {
                    case let .a(val1, param2):
                        return (val1, param2)
                    default:
                        return nil
                    }
                }

                func getTestCase() -> (String)? {
                    switch self {
                    case let .testCase(testValue):
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

    func testDiagnosesBadMustacheTemplate() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum Subtype: String {
                {{#cases}
                case {{name}}
                {{/cases}}
            }
            """)
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "mustacheTemplateError"
                ),
                message: """
                Error while rendering the template: unfinishedName
                """,
                line: 3,
                column: 1,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesBadProducedSwiftCode() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum Subtype: String {
                {{#cases}}
                case "{{name}}"
                {{/cases}}
            }
            """)
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a(val1: String, Int)
                case b
                case testCase(testValue: String)
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "renderedSyntaxContainsErrors"
                ),
                message: """
                Rendered syntax contains errors:
                enum Subtype: String {
                    case "a"
                    case "b"
                    case "testCase"
                }
                """,
                line: 1,
                column: 13,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }
}
