import SwiftSyntaxMacros
import SwiftSyntax

/// The macro works in a single thread so `@unchecked Sendable` is justified.
final class RenderingContext: @unchecked Sendable {
    @TaskLocal static var current: RenderingContext!

    let context: any MacroExpansionContext
    let node: Syntax
    var allowedComments: Arguments.AllowedComments?
    var threwAllowedCommentsError = false
    var diagnostic: MacroError?

    init(
        node: Syntax,
        context: any MacroExpansionContext,
        allowedComments: Arguments.AllowedComments?
    ) {
        self.node = node
        self.context = context
        self.allowedComments = allowedComments
        self.diagnostic = nil
    }

    func addOrReplaceDiagnostic(_ error: MacroError) {
        self.diagnostic = error
    }
}
