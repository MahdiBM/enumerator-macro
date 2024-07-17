/// The macro works in a single thread so `@unchecked Sendable` is justified.
final class RenderingContext: @unchecked Sendable {
    @TaskLocal static var current: RenderingContext!

    var diagnostic: MacroError?

    func addOrReplaceDiagnostic(_ error: MacroError) {
        self.diagnostic = error
    }
}
