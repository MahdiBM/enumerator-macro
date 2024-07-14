import SwiftSyntax

final class Rewriter: SyntaxRewriter {
    override func visit(_ node: SwitchCaseSyntax) -> SwitchCaseSyntax {
        self.removeUnusedLet(
            self.removeUnusedArguments(
                node
            )
        )
    }

    /// Rewrites and removed unused arguments in switch cases.
    /// For example, it rewrites:
    /// ```swift
    /// switch self {
    /// case let .testCase(x, y):
    ///     return x
    /// ```
    /// to:
    /// ```swift
    /// switch self {
    /// case .testCase(x):
    /// ```
    /// because `y` is unused.
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

            var missingPresenceIndices: [Int] = []
            for (idx, argument) in functionCallSyntax.arguments.enumerated() {
                guard let patternExpr = argument.expression.as(PatternExprSyntax.self),
                      let identifier = patternExpr.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }
                let presenceDetector = PresenceDetector(toDetect: identifier.identifier.tokenKind)
                presenceDetector.walk(node)
                if presenceDetector.detectCount < 2 {
                    missingPresenceIndices.append(idx)
                }
            }

            var arguments = functionCallSyntax.arguments

            for (index, idxInArguments) in missingPresenceIndices.enumerated() {
                let idx = arguments.index(at: idxInArguments - index)
                arguments.remove(at: idx)
            }

            if !missingPresenceIndices.isEmpty {
                let innerExpression: ExprSyntax = if arguments.isEmpty {
                    functionCallSyntax.calledExpression
                } else {
                    ExprSyntax(
                        functionCallSyntax.with(
                            \.arguments,
                             arguments.with(
                                /// Remove the trailing comma from the last arg, if it's there.
                                \.[arguments.lastIndex(where: { _ in true })!],
                                 arguments.last!.with(
                                    \.trailingComma,
                                     nil
                                 )
                             )
                        )
                    )
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
