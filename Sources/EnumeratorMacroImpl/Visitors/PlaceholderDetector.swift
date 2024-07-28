import SwiftSyntax

#if canImport(SwiftSyntax600)
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
