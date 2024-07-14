import SwiftSyntax

final class Rewriter: SyntaxRewriter {
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        let newNode = self.removeUnusedLet(node)
        return newNode
    }

    /// Rewrites and removed unused `let`s in switch cases.
    /// For example, it rewrites:
    /// ```swift
    /// switch self {
    /// case let .testCase:
    /// ```
    /// to:
    /// ```swift
    /// switch self {
    /// case .testCase:
    /// ```
    private func removeUnusedLet(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard var label = node.label.as(SwitchCaseLabelSyntax.self) else {
            return node
        }
        var items = label.caseItems

        for (idx, item) in items.enumerated() {
            guard let pattern = item.pattern.as(ValueBindingPatternSyntax.self),
                  pattern.bindingSpecifier.tokenKind == .keyword(.let),
                  let expr = pattern.pattern.as(ExpressionPatternSyntax.self),
                  expr.expression.is(MemberAccessExprSyntax.self) else {
                continue
            }
            let idx = items.index(at: idx)
            let newPattern = expr
            items[idx].pattern = PatternSyntax(newPattern)
        }

        label.caseItems = items
        var node = node
        node.label = SwitchCaseSyntax.Label(label)

        return node
    }
}
