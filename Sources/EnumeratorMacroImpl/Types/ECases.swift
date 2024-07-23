import Mustache
import SwiftSyntax
import SwiftSyntaxMacros

struct ECases {
    fileprivate let underlying: EArray<ECase>

    init(underlying: [ECase]) {
        self.underlying = .init(underlying: underlying)
    }

    init(elements: [EnumCaseElementSyntax]) throws {
        let lastIdx = elements.count - 1
        self.underlying = .init(
            underlying: try elements.enumerated().map {
                idx,
                element in
                try ECase(
                    from: element,
                    index: idx,
                    isFirst: idx == 0,
                    isLast: idx == lastIdx
                )
            }
        )
    }

    func checkCommentsOnlyContainAllowedKeysOrDiagnose(
        arguments: Arguments,
        context: some MacroExpansionContext
    ) -> Bool {
        guard let allowedComments = arguments.allowedComments,
              !allowedComments.keys.isEmpty else {
            return true
        }
        var allGood = true
        for casee in self.underlying {
            for comment in casee.comments {
                if !comment.checkKeyIsAllowedInComments(
                    allowedComments: allowedComments,
                    node: casee.node,
                    context: context
                ) {
                    allGood = false
                }
            }
        }
        return allGood
    }
}

extension ECases: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension ECases: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[Case]"
    }
}

extension ECases: Sequence, MustacheSequence {
    func makeIterator() -> Array<ECase>.Iterator {
        self.underlying.makeIterator()
    }
}

extension ECases: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension ECases: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        /// The underlying type is in charge of adding a diagnostic, if needed.
        return self.underlying.transform(name)
    }
}
