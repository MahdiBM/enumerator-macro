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
            func get{{capitalized(name)}}() -> ({{joined(tupleValue(parameters))}})? {
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

    func testProperlyReadsComments() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            public var isBusinessLogicError: Bool {
                switch self {
                {{#cases}}
                case let .{{name}}:
                    return {{bool(business_error(keyValues(comments)))}}
                {{/cases}}
                }
            }
            """)
            public enum ErrorMessage {
                case case1 // business_error
                case case2 // business_error: true
                case case3 // business_error: false
                case case4 // business_error: adfasdfdsff
                case somethingSomething(integration: String)
                case otherCase(error: Error, isViolation: Bool) // business_error; l8n_params:
            }
            """#,
            expandedSource: #"""
            public enum ErrorMessage {
                case case1 // business_error
                case case2 // business_error: true
                case case3 // business_error: false
                case case4 // business_error: adfasdfdsff
                case somethingSomething(integration: String)
                case otherCase(error: Error, isViolation: Bool) // business_error; l8n_params:

                public var isBusinessLogicError: Bool {
                    switch self {
                    case .case1:
                        return true
                    case .case2:
                        return true
                    case .case3:
                        return false
                    case .case4:
                        return false
                    case .somethingSomething:
                        return false
                    case .otherCase:
                        return true
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesNotAnEnum() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum Subtype: String {
                {{#cases}
                case {{name}}
                {{/cases}}
            }
            """)
            struct TestString {
                let value: String
            }
            """#,
            expandedSource: #"""
            struct TestString {
                let value: String
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "isNotEnum"
                ),
                message: """
                Only enums are supported
                """,
                line: 1,
                column: 1,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesNoArguments() throws {
        assertMacroExpansion(
            #"""
            @Enumerator
            enum TestEnum {
                case a
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "macroDeclarationHasNoArguments"
                ),
                message: """
                The macro declaration needs to have at least 1 String-Literal argument
                """,
                line: 1,
                column: 1,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesEmptyArguments() throws {
        assertMacroExpansion(
            #"""
            @Enumerator
            enum TestEnum {
                case a
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "macroDeclarationHasNoArguments"
                ),
                message: """
                The macro declaration needs to have at least 1 String-Literal argument
                """,
                line: 1,
                column: 1,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesUnacceptableArguments() throws {
        assertMacroExpansion(
            #"""
            @Enumerator(myVariable)
            enum TestEnum {
                case a
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
                case a
            }
            """#,
            diagnostics: [.init(
                id: .init(
                    domain: "EnumeratorMacro.MacroError",
                    id: "allArgumentsMustBeNonInterpolatedStringLiterals"
                ),
                message: """
                All arguments must be non-interpolated string literals.
                """,
                line: 1,
                column: 13,
                severity: .error
            )],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testDiagnosesStringInterpolationInMustacheTemplate() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            enum Subtype: String {
                {{#cases}}
                case \(name)
                {{/cases}}
                \(comments)
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
            diagnostics: [
                .init(
                    id: .init(
                        domain: "EnumeratorMacro.MacroError",
                        id: "allArgumentsMustBeNonInterpolatedStringLiterals"
                    ),
                    message: """
                    All arguments must be non-interpolated string literals.
                    """,
                    line: 4,
                    column: 10,
                    severity: .error
                ),
                .init(
                    id: .init(
                        domain: "EnumeratorMacro.MacroError",
                        id: "allArgumentsMustBeNonInterpolatedStringLiterals"
                    ),
                    message: """
                    All arguments must be non-interpolated string literals.
                    """,
                    line: 6,
                    column: 5,
                    severity: .error
                )
            ],
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

    func testDiagnosesErroneousSwiftCode() throws {
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
            diagnostics: [
                .init(
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
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "MissingNodesError"
                    ),
                    message: """
                    expected identifier in enum case
                    """,
                    line: 2,
                    column: 17,
                    severity: .error,
                    fixIts: [.init(
                        message: "insert identifier"
                    )]
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "UnexpectedNodesError"
                    ),
                    message: """
                    unexpected code '"a"' before enum case
                    """,
                    line: 2,
                    column: 17,
                    severity: .error
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "MissingNodesError"
                    ),
                    message: """
                    expected identifier in enum case
                    """,
                    line: 3,
                    column: 7,
                    severity: .error,
                    fixIts: [.init(
                        message: "insert identifier"
                    )]
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "UnexpectedNodesError"
                    ),
                    message: """
                    unexpected code '"b"' before enum case
                    """,
                    line: 3,
                    column: 7,
                    severity: .error
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "MissingNodesError"
                    ),
                    message: """
                    expected identifier in enum case
                    """,
                    line: 4,
                    column: 5,
                    severity: .error,
                    fixIts: [.init(
                        message: "insert identifier"
                    )]
                ),
                .init(
                    id: .init(
                        domain: "SwiftParser",
                        id: "UnexpectedNodesError"
                    ),
                    message: """
                    unexpected code '"testCase"' in enum
                    """,
                    line: 4,
                    column: 5,
                    severity: .error
                ),
            ],
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

    func testRemovesUnusedLetInSwitchStatements() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            var isTestCase: Bool {
                switch self {
                case let .testCase:
                    return true
                default:
                    return false
                }
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

    func testRemovesArgumentInSwitchStatements() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            var isTestCase: Bool {
                switch self {
                case let .testCase(asd):
                    return true
                default:
                    return false
                }
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

    func testRemovesArgumentInSwitchStatementsWithMultipleArgumentsWhereOneArgIsUsed() throws {
        assertMacroExpansion(
            #"""
            @Enumerator("""
            var isTestCase: Bool {
                switch self {
                case let .a(x, y):
                    return x
                default:
                    return false
                }
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

                var isTestCase: Bool {
                    switch self {
                    case let .a(x, _):
                        return x
                    default:
                        return false
                    }
                }
            }
            """#,
            macros: EnumeratorMacroEntryPoint.macros
        )
    }

//    func testAppliesFixIts() throws {
//        assertMacroExpansion(
//            #"""
//            @Enumerator("""
//            var value: Int {
//                a 1️⃣\u{a0}+ 2
//            }
//            """)
//            enum TestEnum {
//                case a(val1: String, Int)
//                case b
//                case testCase(testValue: String)
//            }
//            """#,
//            expandedSource: #"""
//            enum TestEnum {
//                case a(val1: String, Int)
//                case b
//                case testCase(testValue: String)
//
//                var value: Int {
//                    a  + 2
//                }
//            }
//            """#,
//            macros: EnumeratorMacroEntryPoint.macros
//        )
//    }
}

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
""",
"""
var isTestCase2: Bool {
    switch self {
    case let .testCase:
        return true
    default:
        return false
    }
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
