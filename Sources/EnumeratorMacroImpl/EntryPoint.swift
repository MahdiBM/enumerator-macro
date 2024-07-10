import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct EnumeratorMacroEntryPoint: CompilerPlugin {
    public static let macros: [String: any Macro.Type] = [
        "Enumerator": EnumeratorMacroType.self
    ]

    public let providingMacros: [any Macro.Type] = macros.map(\.value)

    public init() {}
}
