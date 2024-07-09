import EnumeratorMacro
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite struct EnumeratorMacroTests {
    @Test func works() throws {
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
            public enum TestEnum {
                case a
                case b
            }
            """#,
            expandedSource: #"""
            public enum TestEnum {
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
}

@attached(member, names: arbitrary)
macro Enumerator(_ templates: String...) = #externalMacro(
    module: "EnumeratorMacro",
    type: "EnumeratorMacroType"
)




/// {{#namesWithTypes(parameters)}}{{joined(.)}}{{/namesWithTypes(parameters)}}

@Enumerator("""
enum CopyOfSelf: String {
{{#cases}}
case {{name}}{{#namesWithTypes(parameters)}}{{joined(.)}}{{/namesWithTypes(parameters)}}
{{/cases}}
}
""")
public enum TestEnum2 {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
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
public enum TestEnum {
    case a(value: String)
    case b
    case testCase(testValue: String)

    func isTheSameCase(as other: Self) -> Bool {
        self.subtype == other.subtype
    }
}

@Enumerator("""
{{#cases}}
var is{{capitalized(name)}}: Bool {
    switch self {
    case .{{name}}: true
    default: false
    }
}
{{/cases}}
""")
public enum TestEnum3 {
    case a(value: String)
    case b
    case testCase(testValue: String)
}
