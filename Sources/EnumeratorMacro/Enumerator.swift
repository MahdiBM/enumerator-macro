@attached(member, names: arbitrary)
public macro Enumerator(_ templates: StaticString...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

@attached(member, names: arbitrary)
macro CreateSubtype() = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

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

@CreateSubtype
enum TestEnum2 {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
