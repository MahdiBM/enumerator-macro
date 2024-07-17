@testable import EnumeratorMacroImpl
import Mustache
import XCTest

final class TransformTests: XCTestCase {
    func testCommentsValueIsEmptyBecauseDoesNotExist() throws {
        do {
            let template = "{{empty(custom_params(keyValues(comments)))}}"
            let render = try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render(
                testCases[0]
            )
            XCTAssertEqual(render, "true")
        }

        do {
            let template = "{{exists(custom_params(keyValues(comments)))}}"
            let render = try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render(
                testCases[0]
            )
            XCTAssertEqual(render, "false")
        }
    }

    func testCommentsValueIsEmptyButExists() throws {
        do {
            let template = "{{empty(custom_params(keyValues(comments)))}}"
            let render = try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render(
                testCases[3]
            )
            XCTAssertEqual(render, "true")
        }

        do {
            let template = "{{exists(custom_params(keyValues(comments)))}}"
            let render = try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render(
                testCases[3]
            )
            XCTAssertEqual(render, "true")
        }
    }

    func testCommentsValueConditionalSection() throws {
        do {
            let template = """
            {{^exists(custom_params(keyValues(comments)))}}
            thing!
            {{/exists(custom_params(keyValues(comments)))}}
            """
            let render = try MustacheTemplate(
                string: "{{%CONTENT_TYPE:TEXT}}\n" + template
            ).render(
                testCases[2]
            )
            XCTAssertEqual(render, "thing!\n")
        }
    }

    let testCases: [ECase] = [
        ECase(
            index: 0,
            name: "case1",
            parameters: .init(underlying: []),
            comments: ["bool_value"]
        ),
        ECase(
            index: 1,
            name: "case2",
            parameters: .init(underlying: []),
            comments: []
        ),
        ECase(
            index: 2,
            name: "case3",
            parameters: .init(underlying: [EParameter(
                name: "thing",
                type: "String",
                isOptional: false
            )]),
            comments: []
        ),
        ECase(
            index: 3,
            name: "case4",
            parameters: .init(underlying: [
                EParameter(
                    name: "error",
                    type: "Error",
                    isOptional: false
                ),
                EParameter(
                    name: "critical",
                    type: "Bool",
                    isOptional: false
                )
            ]),
            comments: ["bool_value", "custom_params:"]
        )
    ]
}
