import SwiftSyntax
import SwiftSyntaxMacrosGenericTestSupport
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import Testing

func assertMacroExpansionWithSwiftTesting(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: any Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    sourceLocation: Testing.SourceLocation
) {
    let macroSpecs = macros.mapValues { MacroSpec(type: $0) }
    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: {
            #expect(Bool(false), .init(stringLiteral: $0.message), sourceLocation: sourceLocation)
        },
        fileID: "",  // Not used in the failure handler
        filePath: "", // (MahdiBM Note): Requires static string
        line: UInt(sourceLocation.line),
        column: 0  // Not used in the failure handler
    )
}
