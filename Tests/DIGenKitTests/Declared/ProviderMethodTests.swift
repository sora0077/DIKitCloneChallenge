//
//  ProviderMethodTests.swift
//  DIGenKitTests
//
//  Created by 林達也 on 2018/10/02.
//

import XCTest
import SwiftSyntax

@testable import DIGenKit

private extension FunctionParameterListSyntax {
    var array: [Element] { return Array(self) }
}

final class ProviderMethodTests: XCTestCase {

    func test() throws {
        let tempDir = try temporaryDirectory()
        let file = try makeFile("Foo.swift", in: tempDir) {
            """
            protocol Test: Resolver {
                func provideA(b: B, c: C) -> A
            }
            """
        }

        class Collector: SyntaxVisitor {
            var protocols = Set<ProtocolDeclSyntax>()

            override func visit(_ node: ProtocolDeclSyntax) {
                protocols.insert(node)
                super.visit(node)
            }
        }

        let collector = Collector()
        try collector.visit(SyntaxTreeParser.parse(file.asURL))

        XCTAssertEqual(collector.protocols.count, 1)

        let decl = collector.protocols.removeFirst()
        let method = try ProviderMethod.providerMethods(in: decl).first

        XCTAssertNotNil(method)
        XCTAssertEqual(method?.decl.identifier.text, "provideA")
        XCTAssertEqual(method?.decl.signature.output?.returnType.helper.name?.text, "A")
        XCTAssertEqual(method?.decl.signature.input.parameterList.count, 2)
        XCTAssertEqual(method?.decl.signature.input.parameterList.array[0].firstName?.text, "b")
        XCTAssertEqual(method?.decl.signature.input.parameterList.array[0].type?.helper.name?.text, "B")
        XCTAssertEqual(method?.decl.signature.input.parameterList.array[1].firstName?.text, "c")
        XCTAssertEqual(method?.decl.signature.input.parameterList.array[1].type?.helper.name?.text, "C")
    }

    static var allTests = [
        ("test", test)
    ]
}
