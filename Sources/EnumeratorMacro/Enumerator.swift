import EnumeratorMacroImpl

@attached(member, names: arbitrary)
public macro Enumerator(_ templates: String...) = #externalMacro(
    module: "EnumeratorMacro",
    type: "EnumeratorMacroType"
)
