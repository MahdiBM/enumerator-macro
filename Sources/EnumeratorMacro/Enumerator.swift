@attached(member, names: arbitrary)
public macro Enumerator(
    allowedComments: [String] = [],
    _ templates: String...
) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)
