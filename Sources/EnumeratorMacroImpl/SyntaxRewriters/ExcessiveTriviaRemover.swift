import SwiftSyntax

final class ExcessiveTriviaRemover: SyntaxRewriter {
    /// Remove empty lines.
    override func visitAny(_ node: Syntax) -> Syntax? {
        var node = node
        let leadingModified, trailingModified: Bool
        (leadingModified, node) = self.handleTrivia(node, at: \.leadingTrivia)
        (trailingModified, node) = self.handleTrivia(node, at: \.trailingTrivia)
        let modified = leadingModified || trailingModified
        return modified ? self.rewrite(node) : nil
    }

    func handleTrivia(
        _ node: Syntax,
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
                   case .newlines = pieces[idx + 1] {
                    /// Previous and next are both `newlines`.
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
                   let last = result.last,
                   case let .newlines(countLast) = last {
                    result[result.count - 1] = .newlines(countNext + countLast)
                } else {
                    result.append(next)
                }
            }
        }

        pieces = pieces.map { piece in
            if case let .newlines(count) = piece,
               count > 1 {
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
