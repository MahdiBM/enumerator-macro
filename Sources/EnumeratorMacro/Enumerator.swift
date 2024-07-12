@attached(member, names: arbitrary)
public macro Enumerator(_ templates: StaticString...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)
