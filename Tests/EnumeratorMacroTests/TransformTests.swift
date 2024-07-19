@testable import EnumeratorMacroImpl
import Mustache
import XCTest

final class TransformTests: XCTestCase {
    func testCommentsValueIsEmptyBecauseDoesNotExist() throws {
        do {
            let template = "{{isEmpty(custom_params(keyValues(comments)))}}"
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
            let template = "{{isEmpty(custom_params(keyValues(comments)))}}"
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

    let testCases: [ECase] = [
        ECase(
            node: .init(name: .identifier("empty")),
            name: "case1",
            parameters: .init(underlying: []),
            comments: ["bool_value"],
            index: 0,
            isFirst: true,
            isLast: false
        ),
        ECase(
            node: .init(name: .identifier("empty")),
            name: "case2",
            parameters: .init(underlying: []),
            comments: [],
            index: 1,
            isFirst: false,
            isLast: false
        ),
        ECase(
            node: .init(name: .identifier("empty")),
            name: "case3",
            parameters: .init(underlying: [EParameter(
                name: "thing",
                type: "String",
                isOptional: false,
                index: 0,
                isFirst: true,
                isLast: true
            )]),
            comments: [],
            index: 2,
            isFirst: false,
            isLast: false
        ),
        ECase(
            node: .init(name: .identifier("empty")),
            name: "case4",
            parameters: .init(underlying: [
                EParameter(
                    name: "error",
                    type: "Error",
                    isOptional: false,
                    index: 0,
                    isFirst: true,
                    isLast: false
                ),
                EParameter(
                    name: "critical",
                    type: "Bool",
                    isOptional: false,
                    index: 1,
                    isFirst: false,
                    isLast: true
                )
            ]),
            comments: ["bool_value", "custom_params:"],
            index: 3,
            isFirst: false,
            isLast: true
        )
    ]
}
