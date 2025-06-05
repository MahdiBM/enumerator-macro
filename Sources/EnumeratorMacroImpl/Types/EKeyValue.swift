import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Mustache
/// Importing foundation for `.trimmingCharacters(in: .whitespacesAndNewlines)`
import Foundation

struct EKeyValue {
    let key: EString
    let value: EString

    init? (from string: String) {
        let split = string.split(
            separator: ":",
            maxSplits: 1
        ).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter {
            !$0.isEmpty
        }
        guard split.count > 0 else {
            return nil
        }
        self.key = EString(split[0])
        self.value = EString(split.count > 1 ? split[1] : "")
    }

    func checkKeyIsAllowedInComments(
        allowedComments: Arguments.AllowedComments,
        node: EnumCaseElementSyntax,
        context: some MacroExpansionContext
    ) -> Bool {
        let key = self.key.underlying
        if !allowedComments.keys.contains(key) {
            context.addDiagnostics(
                from: MacroError.commentKeyNotAllowed(key: key),
                node: node
            )
            context.diagnose(
                Diagnostic(
                    node: allowedComments.node,
                    message: MacroError.declaredHere(name: "'allowedComments'")
                )
            )
            return false
        } else {
            return true
        }
    }
}

extension EKeyValue: CustomStringConvertible {
    var description: String {
        "(key: \(key), value: \(value))"
    }
}

extension EKeyValue: WithNormalizedTypeName {
    static var normalizedTypeName: String {
        "KeyValue<String, String>"
    }
}

extension EKeyValue: Comparable {
    static func < (lhs: EKeyValue, rhs: EKeyValue) -> Bool {
        lhs.key < rhs.key
    }

    static func == (lhs: EKeyValue, rhs: EKeyValue) -> Bool {
        lhs.key == rhs.key
    }
}

extension EKeyValue: EMustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "key":
            return self.key
        case "value":
            return self.value
        default:
            RenderingContext.current.addOrReplaceFunctionDiagnostic(
                .invalidTransform(
                    transform: name,
                    normalizedTypeName: Self.normalizedTypeName
                )
            )
            return nil
        }
    }
}
