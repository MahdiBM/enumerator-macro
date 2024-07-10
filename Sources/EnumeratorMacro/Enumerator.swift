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

let staticString: StaticString = """
    enum Subtype: String {
        {{#cases}}
        case {{name}}
        {{/cases}}
    }
    """

@Enumerator(staticString)
enum TestEnumd2 {
    case a(value: String)
    case b
    case f
    case testCase(testValue: String)

//    func dso() {
//        let a = Subtype.a
//    }
}
