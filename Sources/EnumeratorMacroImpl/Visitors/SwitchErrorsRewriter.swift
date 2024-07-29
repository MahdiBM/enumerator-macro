import SwiftSyntax

final class SwitchErrorsRewriter: SyntaxRewriter {
    /// Rewrites and removes the trailing comma of the last case which is an error in Swift.
    /// For example, it rewrites:
    /// ```swift
    /// switch self {
    /// case
    ///     .a,
    ///     .b,
    ///     :
    ///     return x
    /// ```
    /// to:
    /// ```swift
    /// switch self {
    /// case
    ///     .a,
    ///     .b
    ///     :
    ///     return x
    /// ```
    /// so it removes the `,` after `b` which is the last case.
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard let label = node.label.as(SwitchCaseLabelSyntax.self) else {
            return node
        }
        var items = label.caseItems
        guard items.count > 1 else {
            return node
        }

        let lastIndex = items.lastIndex(where: { _ in true })!
        var lastIsAMissingExpr: Bool {
            if let pattern = items[lastIndex].pattern.as(ExpressionPatternSyntax.self),
               pattern.expression.is(MissingExprSyntax.self) {
                return true
            } else {
                return false
            }
        }

        var oneToLastContainsTrailingComma: Bool {
            items[items.index(before: lastIndex)].trailingComma != nil
        }

        if lastIsAMissingExpr,
           oneToLastContainsTrailingComma {

            items[items.index(before: lastIndex)].trailingComma = nil
            items.remove(at: lastIndex)

            let node = node.with(
                \.label,
                 SwitchCaseSyntax.Label(
                    label.with(
                        \.caseItems,
                         items
                    )
                 )
            )
            return node
        } else {
            return node
        }
    }
}
