import SwiftSyntax

final class PlaceholderDetector: SyntaxVisitor {
    var containedPlaceholder = false

    override init(viewMode: SyntaxTreeViewMode = .sourceAccurate) {
        super.init(viewMode: viewMode)
    }
    
    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        if node.isEditorPlaceholder {
            self.containedPlaceholder = true
            return .skipChildren
        }
        return .visitChildren
    }
}
