//
//  ResolverTests.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/08.
//

import XCTest
@testable import DIGenKit

import SwiftSyntax

private class Collector: SyntaxVisitor {
    var nodes = [Declared.Resolver]()
    var errors = [Error]()

    override func visit(_ node: ProtocolDeclSyntax) {
        super.visit(node)
        do {
            if let resolver = try Declared.Resolver(decl: node) {
                nodes.append(resolver)
            }
        } catch {
            errors.append(error)
        }
    }
}

class ResolverTests: XCTestCase {
    func test() throws {

        let tempDir = try temporaryDirectory()
        let collector = Collector()
        try collector.visit(makeSourceSyntax("Foo.swift", in: tempDir) {
            """
            protocol Test: Resolver {
                func provideA(b: B, c: C?) -> A
            }
            """
        })

        guard let resolver = collector.nodes.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(resolver.providedFunctions.count, 1)
        XCTAssertEqual(resolver.providedFunctions[0].methodName, "provideA")
        XCTAssertEqual(resolver.providedFunctions[0].arguments.map { $0.label }, ["B", "C?"])
        XCTAssertEqual(resolver.providedFunctions[0].returnType.name, "A")
    }

    func testMissingReturnType() throws {
        let tempDir = try temporaryDirectory()
        let collector = Collector()
        try collector.visit(makeSourceSyntax("Foo.swift", in: tempDir) {
            """
            protocol Test: Resolver {
                func provideA(b: B, c: C)
            }
            """
        })

        do {
            XCTAssertEqual(collector.errors.count, 1)
            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Resolver.ProvidedFunction.Error {
            XCTAssertEqual(error.reason, .returnTypeNotFound)
        } catch {
            XCTFail()
        }
    }

    func testStatic() throws {
        let tempDir = try temporaryDirectory()
        let collector = Collector()
        try collector.visit(makeSourceSyntax("Foo.swift", in: tempDir) {
            """
            protocol Test: Resolver {
                static func provideA(b: B, c: C) -> A
            }
            """
        })

        do {
            XCTAssertEqual(collector.errors.count, 1)
            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Resolver.ProvidedFunction.Error {
            XCTAssertEqual(error.reason, .nonInstanceMethod)
        } catch {
            XCTFail()
        }
    }

    static var allTests = [
        ("test", test),
        ("testMissingReturnType", testMissingReturnType),
        ("testStatic", testStatic)
    ]
}
