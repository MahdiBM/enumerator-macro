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

    var caseName: String {
        switch self {
        case .a: "a"
        case .b: "b"
        case .testCase: "testCase"
        }
    }
}
```

### Create a Subtype Enum

```swift
@Enumerator("""
{{#cases}}
var is{{firstCapitalized(name)}}: Bool {
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

    var isTestCase: Bool {
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
    case {{name}}{{withParens(joined(namesAndTypes(parameters)))}}
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

###  Create Functions For Each Case

```swift
@Enumerator("""
{{#cases}}
{{^empty(parameters)}}
func get{{firstCapitalized(name)}}() -> ({{joined(tupleValue(parameters))}})? {
    switch self {
    case let .{{name}}{{withParens(joined(names(parameters)))}}:
        return {{withParens(joined(names(parameters)))}}
    default:
        return nil
    }
}
{{/empty(parameters)}}
{{/cases}}
""")
enum TestEnum {
    case a(val1: String, Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```swift
enum TestEnum {
    case a(val1: String, Int)
    case b
    case testCase(testValue: String)

    func getA() -> (val1: String, param2: Int)? {
        switch self {
        case let .a(val1, param2):
            return (val1, param2)
        default:
            return nil
        }
    }

    func getTestCase() -> (String)? {
        switch self {
        case let .testCase(testValue):
            return (testValue)
        default:
            return nil
        }
    }
}
```

## How To Add EnumeratorMacro To Your Project

To use the `EnumeratorMacro` library in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/MahdiBM/EnumeratorMacro", branch: "main"),
```

Include `EnumeratorMacro` as a dependency for your targets:

```swift
.target(name: "<target>", dependencies: [
    .product(name: "EnumeratorMacro", package: "EnumeratorMacro"),
]),
```

Finally, add `import EnumeratorMacro` to your source code.
