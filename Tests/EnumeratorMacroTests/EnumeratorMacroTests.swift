import EnumeratorMacro
import EnumeratorMacroImpl
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite struct EnumeratorMacroTests {
    @Test func createsCaseName() throws {
        assertMacroExpansionWithSwiftTesting(
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
            macros: EnumeratorMacroEntryPoint.macros,
            sourceLocation: Testing.SourceLocation()
        )
    }

    @Test func createsACopyOfSelf() throws {
        assertMacroExpansionWithSwiftTesting(
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
            macros: EnumeratorMacroEntryPoint.macros,
            sourceLocation: Testing.SourceLocation()
        )
    }

    @Test func createsDeclarationsForCaseChecking() throws {
        assertMacroExpansionWithSwiftTesting(
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
            macros: EnumeratorMacroEntryPoint.macros,
            sourceLocation: Testing.SourceLocation()
        )
    }

    @Test func createsSubtypeWithMulti() throws {
        assertMacroExpansionWithSwiftTesting(
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
            macros: EnumeratorMacroEntryPoint.macros,
            sourceLocation: Testing.SourceLocation()
        )
    }
}

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
        return .{{name}}
    {{/cases}}
    }
}
""",
"""
var parameterNames: [String] {
    switch self {
    {{#cases}}
    case .{{name}}:
        return [
{{^parameters}}
"empty"
{{/parameters}}
{{#parameters}}
"{{snakeCased(name)}}"
{{/parameters}}
        ]
    {{/cases}}
    }
}
""",
"""
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
    case a(value: String)
    case b
    case testCase(testValue: String)

    func isTheSameCase(as other: Self) -> Bool {
        self.subtype == other.subtype
    }
}
