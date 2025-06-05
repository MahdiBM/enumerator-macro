import SwiftSyntax

#if canImport(SwiftSyntax600) || canImport(SwiftSyntax601) || canImport(SwiftSyntax602) || canImport(SwiftSyntax603)
final class PlaceholderDetector: SyntaxVisitor {
    var containsPlaceholder = false

    override init(viewMode: SyntaxTreeViewMode = .sourceAccurate) {
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        if node.isEditorPlaceholder {
            self.containsPlaceholder = true
            return .skipChildren
        }
        return .visitChildren
    }
}
#endif
