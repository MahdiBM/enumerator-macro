import Mustache

struct EKeyValue {
    let key: EString
    let value: EString

    init(key: EString, value: EString) {
        self.key = key
        self.value = value
    }
}

extension EKeyValue: CustomStringConvertible {
    var description: String {
        "(key: \(key), value: \(value))"
    }
}

extension EKeyValue: MustacheTransformable {
    func transform(_ name: String) -> Any? {
        switch name {
        case "key":
            return self.key
        case "value":
            return self.value
        default:
            return nil
        }
    }
}
