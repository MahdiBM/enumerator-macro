import SwiftSyntax

final class ExcessiveTriviaRemover: SyntaxRewriter {
    /// Removes empty lines.
    override func visitAny(_ node: Syntax) -> Syntax? {
        var node = node
        let leadingModified: Bool
        let trailingModified: Bool
        (leadingModified, node) = self.removeEmptyLineTrivia(from: node, at: \.leadingTrivia)
        (trailingModified, node) = self.removeEmptyLineTrivia(from: node, at: \.trailingTrivia)
        let modified = leadingModified || trailingModified
        /// Recursively call `rewrite(_:)` if we are not returning `nil`.
        /// Because `SyntaxRewriter`'s implementation will skip
        /// calling `visitAny(_:)` on the children of the node.
        return modified ? self.rewrite(node) : nil
    }

    func removeEmptyLineTrivia(
        from node: Syntax,
        at keyPath: WritableKeyPath<Syntax, Trivia>
    ) -> (modified: Bool, syntax: Syntax) {
        var node = node
        var pieces = node[keyPath: keyPath].pieces
        var modified = false

        var toBeRemoved: [Int] = []
        var previousWasNewLines = true
        for (idx, piece) in pieces.enumerated() {
            switch piece {
            case .newlines:
                previousWasNewLines = true
            case .spaces:
                if previousWasNewLines,
                    idx + 1 < pieces.count,
                    case .newlines = pieces[idx + 1]
                {
                    /// Previous and next are both `newlines`, so remove this `spaces`.
                    toBeRemoved.append(idx)
                }
                previousWasNewLines = false
            default:
                previousWasNewLines = false
            }
        }

        for (idx, index) in toBeRemoved.enumerated() {
            pieces.remove(at: index - idx)
        }
        if !toBeRemoved.isEmpty {
            modified = true
            /// Combine consecutive `newlines` into a single one.
            pieces = pieces.reduce(into: [TriviaPiece]()) { result, next in
                if case let .newlines(countNext) = next,
                    let previous = result.last,
                    case let .newlines(countLast) = previous
                {
                    result[result.count - 1] = .newlines(countNext + countLast)
                } else {
                    result.append(next)
                }
            }
        }

        pieces = pieces.map { piece in
            if case let .newlines(count) = piece,
                count > 1
            {
                modified = true
                return TriviaPiece.newlines(1)
            } else {
                return piece
            }
        }

        if modified {
            node = node.with(
                keyPath,
                Trivia(pieces: pieces)
            )
        }

        return (modified, node)
    }
}
