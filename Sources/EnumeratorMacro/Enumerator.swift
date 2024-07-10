@_exported public import EnumeratorMacroImpl
import SwiftSyntaxMacros

@attached(member, names: arbitrary)
public macro Enumerator(_ templates: String...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

//@attached(member, names: arbitrary)
//macro CreateSubtype(
//    _ template: String = """
//    enum Subtype: String {
//        {{#cases}}
//        case {{name}}
//        {{/cases}}
//    }
//    """
//) = #externalMacro(
//    module: "EnumeratorMacroImpl",
//    type: "EnumeratorMacroType"
//)
//
//@CreateSubtype()
//enum TestEnum2 {
//    case a(value: String)
//    case b
//    case f
//    case testCase(testValue: String)
//
//    func dso() {
//        let a = Subtype.a
//    }
//}
//
//@CreateSubtype()
//enum TestEnumd2 {
//    case a(value: String)
//    case b
//    case f
//    case testCase(testValue: String)
//}

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
