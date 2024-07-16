@attached(member, names: arbitrary)
public macro Enumerator(_ templates: String...) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)
