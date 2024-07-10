import SwiftDiagnostics
import SwiftSyntax
import Mustache

struct EnumCase {
    struct Parameter {
        let name: MString?
        let type: MString

        init(name: String?, type: String) {
            self.name = name.map { .init($0) }
            self.type = .init(type)
        }
    }

    struct Parameters {
        fileprivate let underlying: [Parameter]

        init(underlying: [Parameter]) {
            self.underlying = underlying
        }
    }

    let name: MString
    let parameters: Parameters

    init(from element: EnumCaseElementSyntax) throws {
        self.name = .init(element.name.trimmedDescription)
        let parameters = element.parameterClause?.parameters ?? []
        self.parameters = .init(underlying: parameters.map { parameter in
            Parameter(
                name: (parameter.secondName ?? parameter.firstName)?.trimmedDescription,
                type: parameter.type.trimmedDescription
            )
        })
    }
}

// MARK: - + Parameters

extension EnumCase.Parameters: Sequence, MustacheSequence {
    func makeIterator() -> Array<EnumCase.Parameter>.Iterator {
        self.underlying.makeIterator()
    }
}

//extension EnumCase.Parameters: CustomReflectable {
//    var customMirror: Mirror {
//        Mirror(reflecting: self.underlying)
//    }
//}

extension EnumCase.Parameters: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        if let defaultTransformed = self.underlying.transform(name) {
            return convertToCustomTypesIfPossible(defaultTransformed)
        } else {
            switch name {
            case "joined":
                let joined = self.underlying
                    .map(\.name)
                    .enumerated()
                    .map { $1?.underlying ?? "_unnamed_\($0)" }
                    .joined(separator: ", ")
                let string = MString(joined)
                return string
            case "joinedWithParenthesis":
                let names = self.underlying.map(\.name)
                if names.isEmpty {
                    return MString("")
                } else {
                    let joined = names
                        .enumerated()
                        .map { $1?.underlying ?? "_unnamed_\($0)" }
                        .joined(separator: ", ")
                    let string = MString("(\(joined))")
                    return string
                }
            case "namesWithTypes":
                let namesWithTypes = self
                    .map { ($0.name.map { "\($0): " } ?? "") + $0.type }
                let array = MArray(underlying: namesWithTypes)
                return array
            case "names":
                let names = self.map(\.name)
                let array = MOptionalsArray(underlying: names)
                return array
            case "types":
                let types = self.map(\.type)
                let array = MArray(underlying: types)
                return array
            default:
                return nil
            }
        }
    }
}

extension EnumCase.Parameters: CustomStringConvertible {
    var description: String {
        self.underlying.description
    }
}
