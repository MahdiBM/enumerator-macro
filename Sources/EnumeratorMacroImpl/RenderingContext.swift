import SwiftSyntaxMacros
import SwiftSyntax
import SwiftDiagnostics

/// The macro works in a single thread so `@unchecked Sendable` is justified.
final class RenderingContext: @unchecked Sendable {
    @TaskLocal static var current: RenderingContext!

    private let context: any MacroExpansionContext
    let node: Syntax
    let allowedComments: Arguments.AllowedComments?
    private var emittedAnyDiagnostics: Bool
    private var functionDiagnostic: MacroError?

    init(
        node: Syntax,
        context: any MacroExpansionContext,
        allowedComments: Arguments.AllowedComments?
    ) {
        self.node = node
        self.context = context
        self.allowedComments = allowedComments
        self.emittedAnyDiagnostics = false
        self.functionDiagnostic = nil
    }

    func addOrReplaceFunctionDiagnostic(_ error: MacroError) {
        self.functionDiagnostic = error
    }

    func diagnose(
        error: MacroError,
        node: any SyntaxProtocol
    ) {
        self.context.diagnose(.init(
            node: node,
            message: error
        ))
        self.emittedAnyDiagnostics = true
    }

    /// Returns whether there were any diagnostics emitted at all
    func finishDiagnostics() -> Bool {
        if let diagnostic = self.functionDiagnostic {
            self.context.diagnose(.init(
                node: self.node,
                message: diagnostic
            ))
            return true
        } else if self.emittedAnyDiagnostics {
            return true
        } else {
            return false
        }
    }
}
