import Foundation
import Mustache
import SwiftDiagnostics

struct EComments {
    let underlying: EArray<EKeyValue>

    init(underlying: EArray<EKeyValue>) {
        self.underlying = underlying
    }

    init(underlying: [EKeyValue]) {
        self.underlying = .init(underlying: underlying)
    }
}

extension EComments: Sequence, MustacheSequence {
    func makeIterator() -> Array<EKeyValue>.Iterator {
        self.underlying.makeIterator()
    }
}

extension EComments: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}

extension EComments: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "[KeyValue]"
    }
}

extension EComments: CustomReflectable {
    var customMirror: Mirror {
        Mirror(reflecting: self.underlying)
    }
}

extension EComments: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "first":
            return self.underlying.underlying.first
        case "last":
            return self.underlying.underlying.last
        case "reversed":
            return EComments(underlying: self.underlying.underlying.reversed().map { $0 })
        case "count":
            return self.underlying.underlying.count
        case "isEmpty":
            return self.underlying.underlying.isEmpty
        case "joined":
            let joined = self.underlying.underlying
                .map { String(describing: $0) }
                .joined(separator: ", ")
            let string = EString(joined)
            return string
        case "sorted":
            return EComments(underlying: self.underlying.underlying.sorted())
        case "keyValues":
            RenderingContext.current.diagnose(
                error: .redundantKeyValuesFunctionCall,
                node: RenderingContext.current.node
            )
            return self
        default:
            if let context = RenderingContext.current,
                let allowedComments = context.allowedComments,
                !allowedComments.keys.isEmpty,
                !allowedComments.keys.contains(name)
            {
                context.diagnose(
                    error: .commentKeyNotAllowed(key: name),
                    node: context.node
                )
                context.diagnose(
                    error: .declaredHere(name: "'allowedComments'"),
                    node: allowedComments.node
                )
            }
            return EOptional(
                self.underlying.underlying.first(where: { $0.key.underlying == name })?.value
            )
        }
    }
}
