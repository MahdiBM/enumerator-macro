@attached(member, names: arbitrary)
public macro Enumerator(_ templates: StaticString...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

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
