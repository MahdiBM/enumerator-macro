extension Bool {
    init(_ string: EString) {
        switch string.lowercased() {
        case "true", "1", "yes", "y", "on", "":
            self = true
        default:
            self = false
        }
    }
}
