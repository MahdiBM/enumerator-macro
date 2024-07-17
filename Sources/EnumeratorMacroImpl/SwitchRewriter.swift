import SwiftSyntax

final class SwitchRewriter: SyntaxRewriter {
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        self.removeUnusedLet(
            self.removeUnusedArguments(
                node
            )
        )
    }

    /// Rewrites and removes unused arguments in switch cases.
    /// For example, it rewrites:
    /// ```swift
    /// switch self {
    /// case let .testCase(x, y):
    ///     return x
    /// ```
    /// to:
    /// ```swift
    /// switch self {
    /// case .testCase(x, _):
    ///     return x
    /// ```
    /// so it replaces `y` with `_` because `y` is unused.
    private func removeUnusedArguments(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        guard let label = node.label.as(SwitchCaseLabelSyntax.self) else {
            return node
        }
        var items = label.caseItems

        for (idx, item) in items.enumerated() {
            guard let pattern = item.pattern.as(ValueBindingPatternSyntax.self),
                  let expr = pattern.pattern.as(ExpressionPatternSyntax.self),
                  let functionCallSyntax = expr.expression.as(FunctionCallExprSyntax.self) else {
                continue
            }

            var arguments = functionCallSyntax.arguments
            var didModify = false
            var allArgsAreWildcards = true

            for (idx, argument) in arguments.enumerated() {
                guard let patternExpr = argument.expression.as(PatternExprSyntax.self),
                      let identifier = patternExpr.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                /// Only try to do something if the `tokenKind` is `.identifier`.
                guard case .identifier = identifier.identifier.tokenKind else {
                    let isWildCard = identifier.identifier.tokenKind == .wildcard
                    allArgsAreWildcards = allArgsAreWildcards && isWildCard
                    continue
                }

                let presenceDetector = PresenceDetector(
                    toDetect: identifier.identifier.tokenKind
                )
                presenceDetector.walk(node)
                guard presenceDetector.detectCount < 2 else {
                    allArgsAreWildcards = false
                    continue
                }

                if presenceDetector.detectCount < 2 {
                    /// Doesn't logically do anything, so commented out.
                    /* allArgsAreWildcards = allArgsAreWildcards && true */

                    didModify = true
                    let idx = arguments.index(at: idx)
                    arguments[idx] = arguments[idx].with(
                        \.expression,
                         ExprSyntax(
                            patternExpr.with(
                                \.pattern,
                                 PatternSyntax(
                                    identifier.with(
                                        \.identifier,
                                         .wildcardToken()
                                    )
                                 )
                            )
                         )
                    )
                }
            }

            let innerExpression: ExprSyntax

            switch (didModify, allArgsAreWildcards) {
            case (true, true), (false, true):
                innerExpression = functionCallSyntax.calledExpression
            case (true, false):
                innerExpression = ExprSyntax(
                    functionCallSyntax.with(
                        \.arguments,
                         arguments
                    )
                )
            case (false, false):
                /// Nothing to modify
                continue
            }

            items = items.with(
                \.[items.index(at: idx)].pattern,
                 PatternSyntax(
                    pattern.with(
                        \.pattern,
                         PatternSyntax(
                            expr.with(
                                \.expression,
                                 innerExpression
                            )
                         )
                    )
                 )
            )
        }

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
    }

    /// Rewrites and removes unused `let`s in switch cases.
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
        guard let label = node.label.as(SwitchCaseLabelSyntax.self) else {
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

            items = items.with(
                \.[items.index(at: idx)].pattern,
                 PatternSyntax(expr)
            )
        }

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
    }
}

private final class PresenceDetector: SyntaxVisitor {
    var detectCount = 0
    var toDetect: TokenKind

    init(
        viewMode: SyntaxTreeViewMode = .sourceAccurate,
        toDetect: TokenKind
    ) {
        self.toDetect = toDetect
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        if node.tokenKind == self.toDetect {
            self.detectCount += 1
        }
        return .visitChildren
    }
}
