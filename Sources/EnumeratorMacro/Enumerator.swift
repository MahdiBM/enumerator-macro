@attached(member, names: arbitrary)
public macro Enumerator(
    allowedComments: [String] = [],
    _ templates: String...
) = #externalMacro(
    module: "EnumeratorMacroImpl",
    type: "EnumeratorMacroType"
)

@Enumerator("""
var caseName: String {
    switch self {
    {{#cases}}
    case .{{name}}: "{{#first(parameters)}} {{name}} {{/first(parameters)}}"
    {{/cases}}
    }
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}

public protocol LocalizationServiceProtocol {
    static func localizedString(language: String, term: String, parameters: Any...) -> String
}

package enum SharedConfiguration {
    package enum Env: String {
        case local
        case testing
        case prod
    }

    package static var env: Env { fatalError() }
}

@Enumerator(allowedComments: ["business_error", "l8n_params"],
"""
public enum Subtype: String, Equatable {
    {{#cases}}
    case {{name}}
    {{/cases}}
}
""",
"""
public var subtype: Subtype {
    switch self {
    {{#cases}}
    case .{{name}}:
        .{{name}}
    {{/cases}}
    }
}
""",
"""
public var errorCode: String {
    switch self {
    {{#cases}}
    case .{{name}}:
        "ERROR-{{plusOne(index)}}"
    {{/cases}}
    }
}
""",
"""
public var loggerMetadata: [String: String] {
    switch self {
    {{#cases}} {{^isEmpty(parameters)}}
    case let .{{name}}{{withParens(joined(names(parameters)))}}:
        [
            "caseName": self.caseName,
            {{#names(parameters)}}
            "case_{{.}}": String(reflecting: {{.}}),
            {{/names(parameters)}}
        ]
    {{/isEmpty(parameters)}} {{/cases}}
    default:
        ["caseName": self.caseName]
    }
}
""",
"""
private var localizationParameters: [Any] {
    switch self {
    {{#cases}} {{^isEmpty(parameters)}}

    {{^isEmpty(l8n_params(comments))}}
    case let .{{name}}{{withParens(joined(names(parameters)))}}:
        [{{l8n_params(comments)}}]
    {{/isEmpty(l8n_params(comments))}}

    {{^exists(l8n_params(comments))}}
    case let .{{name}}{{withParens(joined(names(parameters)))}}:
    [
        {{#parameters}}
        {{name}}{{#isOptional}} as Any{{/isOptional}},
        {{/parameters}}
    ]
    {{/exists(l8n_params(comments))}}

    {{/isEmpty(parameters)}} {{/cases}}
    default:
        []
    }
}
""")
@Enumerator(
    allowedComments: ["business_error", "l8n_params"],
    #"""
    package var isBusinessLogicError: Bool {
        switch self {
        case
        {{#cases}}{{#bool(business_error(comments))}}
        .{{name}},
        {{/bool(business_error(comments))}}{{/cases}}
        :
            return true
        default:
            return false
        }
    }
    """#
)
public enum ErrorMessage {
    public static let localizationServiceType: LocalizationServiceProtocol.Type? = nil

    case allergenAlreadyAdded // business_error
    case alreadyOngoingInventory
    case apiKeyWithoutEnoughPermission(integration: String, other: Bool?, Int)
    case databaseError(error: Error, isConstraintViolation: Bool) // business_error; l8n_params:

    public var caseName: String {
        self.subtype.rawValue
    }

    public func toString(_ language: String) -> String {
        let translation = Self.localizationServiceType?.localizedString(
            language: language,
            term: "api.\(self.caseName)",
            parameters: self.localizationParameters
        )
        return translation ?? (SharedConfiguration.env == .testing ? String(reflecting: self) : "<localization failed to load for \(self.caseName)>")
    }
}

