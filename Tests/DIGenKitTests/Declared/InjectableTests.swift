//
//  InjectableTests.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import XCTest
@testable import DIGenKit

import SwiftSyntax

final class InjectableTests: XCTestCase {

    func testDependency() throws {
        class Collector: SyntaxVisitor {
            var nodes = [DeclSyntax]()

            override func visit(_ node: ClassDeclSyntax) {
                super.visit(node)

                nodes.append(node)
            }
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }
                }
                """
            })

            let d = try Declared.Injectable.Dependency(members: collector.nodes.first?.helper.members?.members)

            XCTAssertEqual(d?.dependedTypes.map { $0.name }, ["Int", "Int?"])
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: Injectable {
                    struct Dependency {
                        let userId: Int
                        let error: String = ""
                        let optUserId: Int?
                        static var currentUser: User?
                    }
                }
                """
            })

            XCTAssertThrowsError(
                try Declared.Injectable.Dependency(members: collector.nodes.first?.helper.members?.members)
            )
        } catch Declared.Injectable.Dependency.Error.cannotConstructAssoicatedType {
            XCTAssert(true)
        }
    }

    static var allTests = [
        ("testDependency", testDependency)
    ]
}
