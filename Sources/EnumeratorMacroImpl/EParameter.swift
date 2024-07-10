struct EParameter {
    let name: EString?
    let type: EString

    init(name: String?, type: String) {
        self.name = name.map { .init($0) }
        self.type = .init(type)
    }
}
