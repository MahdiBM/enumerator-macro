import SwiftSyntax

#if compiler(>=6.0)
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
