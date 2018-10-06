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

            XCTAssertEqual(d.dependedTypes.map { $0.name }, ["Int", "Int?"])
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
        } catch Declared.Injectable.Dependency.Error.cannotConstruct {
            XCTAssert(true)
        }
    }

    func testInitializerInjectable() throws {
        class Collector: SyntaxVisitor {
            var nodes = [Declared.Injectable.Initializer]()
            var errors = [Error]()

            override func visit(_ node: ClassDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            override func visit(_ node: EnumDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            override func visit(_ node: StructDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            private func addIfNeeded(_ node: DeclSyntax) {
                do {
                    if let injectable = try Declared.Injectable.Initializer(decl: node) {
                        nodes.append(injectable)
                    }
                } catch {
                    errors.append(error)
                }
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

                    init(dependency: Dependency) {
                        fatalError()
                    }
                }
                struct User: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: DIKit.Dependency) {
                        fatalError()
                    }
                }
                enum User: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: Dependency) {
                        fatalError()
                    }
                }
                struct User {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: DIKit.Dependency) {
                        fatalError()
                    }
                }
                """
            })

            XCTAssertEqual(collector.nodes.count, 3)
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

                extension User {
                    init(dependency: Dependency) {
                        fatalError()
                    }
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Initializer.Error where error.reason == .initializerNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: Injectable {}
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Initializer.Error where error.reason == .associatedTypeNotFound {
            XCTAssert(true)
        }
    }

    func testFactoryInjectable() throws {
        class Collector: SyntaxVisitor {
            var nodes = [Declared.Injectable.Factory]()
            var errors = [Error]()

            override func visit(_ node: ClassDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            override func visit(_ node: EnumDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            override func visit(_ node: StructDeclSyntax) {
                super.visit(node)
                addIfNeeded(node)
            }

            private func addIfNeeded(_ node: DeclSyntax) {
                do {
                    if let injectable = try Declared.Injectable.Factory(decl: node) {
                        nodes.append(injectable)
                    }
                } catch {
                    errors.append(error)
                }
            }
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> User {
                        fatalError()
                    }
                }
                struct User: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> User {
                        fatalError()
                    }
                }
                enum User: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> User {
                        fatalError()
                    }
                }
                struct User {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> User {
                        fatalError()
                    }
                }
                """
                })

            XCTAssertEqual(collector.nodes.count, 3)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }
                }

                extension User {
                    static func makeInstance(dependency: Dependency) -> User {
                        fatalError()
                    }
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Factory.Error where error.reason == .staticMethodNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> Int {
                        fatalError()
                    }
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Factory.Error where error.reason == .staticMethodNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = Collector()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: FactoryInjectable {}
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Factory.Error where error.reason == .associatedTypeNotFound {
            XCTAssert(true)
        }
    }

    static var allTests = [
        ("testDependency", testDependency),
        ("testInitializerInjectable", testInitializerInjectable),
        ("testFactoryInjectable", testFactoryInjectable)
    ]
}
