import SwiftSyntax

final class ExcessiveTriviaRemover: SyntaxRewriter {
    /// Remove empty lines.
    override func visitAny(_ node: Syntax) -> Syntax? {
        var node = node

        var modifiedLeadingTrivia = false
        let newLeadingTrivia = node.leadingTrivia.pieces.map { piece in
            if case let .newlines(count) = piece,
               count > 1 {
                modifiedLeadingTrivia = true
                return TriviaPiece.newlines(1)
            } else {
                return piece
            }
        }
        if modifiedLeadingTrivia {
            node = node.with(
                \.leadingTrivia,
                 Trivia(pieces: newLeadingTrivia)
            )
        }

        var modifiedTrailingTrivia = false
        let newTrailingTrivia = node.trailingTrivia.pieces.map { piece in
            if case let .newlines(count) = piece,
               count > 1 {
                modifiedTrailingTrivia = true
                return TriviaPiece.newlines(1)
            } else {
                return piece
            }
        }
        if modifiedTrailingTrivia {
            node = node.with(
                \.trailingTrivia,
                 Trivia(pieces: newTrailingTrivia)
            )
        }

        let modified = modifiedLeadingTrivia || modifiedTrailingTrivia
        return modified ? self.rewrite(node) : nil
    }
}
