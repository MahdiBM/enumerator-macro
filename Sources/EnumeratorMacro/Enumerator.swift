@_exported public import EnumeratorMacroImpl
import SwiftSyntaxMacros

@attached(member, names: arbitrary)
public macro Enumerator(_ templates: StaticString...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

@attached(member, names: arbitrary)
macro CreateSubtype(
    _ templates: String = """
    enum Subtype: String {
        {{#cases}}
        case {{name}}
        {{/cases}}
    }
    """
) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

@Enumerator("""
enum Subtype: String {
    {{#cases}}
    case {{name}}
    {{/cases}}
}
""")
enum TestEnum2 {
    case a(value: String)
    case b
    case f
    case testCase(testValue: String)

    func dso() {
        let a = Subtype.a
    }
}

@CreateSubtype()
enum TestEnumd2 {
    case a(value: String)
    case b
    case f
    case testCase(testValue: String)

//    func dso() {
//        let a = Subtype.a
//    }
}
