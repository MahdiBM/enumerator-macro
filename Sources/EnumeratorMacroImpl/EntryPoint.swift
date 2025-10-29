#if compiler(>=6.0)
public import SwiftCompilerPlugin
public import SwiftSyntaxMacros
#else
import SwiftCompilerPlugin
import SwiftSyntaxMacros
#endif

@main
public struct EnumeratorMacroEntryPoint: Sendable, CompilerPlugin {
    public static let macros: [String: any Macro.Type] = [
        "Enumerator": EnumeratorMacroType.self
    ]

    public let providingMacros: [any Macro.Type] = macros.map(\.value)

    public init() {}
}
