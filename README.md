# EnumeratorMacro
A utility for creating case-by-case code for your Swift enums using the Mustache templating engine.   
`EnumeratorMacro` uses [swift-mustache](https://github.com/hummingbird-project/swift-mustache/issues/35)'s flavor.

# This is still an unpolished Work-In-Progress

## Examples

### Derive Case Names
```swift
@Enumerator(
"""
var caseName: String {
    switch self {
    {{#cases}}
    case .{{name}}: "{{name}}"
    {{/cases}}
    }
}
"""
)
enum MyEnum {
    case a
    case b
}
```
Is expanded to:
```swift
enum MyEnum {
    case a
    case b

    var caseName: String {
        switch self {
        case .a: "a"
        case .b: "b"
        }
    }
}
```

### Create a Subtype Enum

```swift
@Enumerator("""
{{#cases}}
var is{{capitalized(name)}}: Bool {
    switch self {
    case .{{name}}: return true
    default: return false
    }
}
{{/cases}}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```swift
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

    var isA: Bool {
        switch self {
        case .a: return true
        default: return false
        }
    }

    var isB: Bool {
        switch self {
        case .b: return true
        default: return false
        }
    }

    var isTestcase: Bool {
        switch self {
        case .testCase: return true
        default: return false
        }
    }
}
```

### Create a Copy Of The Enum

Not very practical but I'll leave it here for showcase for now.

```swift
@Enumerator("""
enum Copy {
    {{#cases}}
    case {{name}}{{withParens(joined(namesWithTypes(parameters)))}}
    {{/cases}}
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```swift
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

    enum Copy {
        case a(val1: String, val2: Int)
        case b
        case testCase(testValue: String)
    }
}
```
