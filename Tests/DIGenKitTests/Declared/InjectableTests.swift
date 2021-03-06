//
//  InjectableTests.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import XCTest
@testable import DIGenKit

import SwiftSyntax

private protocol InjectableTarget {

    init?(decl: DeclSyntax) throws
}

extension Declared.Injectable.Initializer: InjectableTarget {}
extension Declared.Injectable.Factory: InjectableTarget {}
extension Declared.Injectable.Property: InjectableTarget {}

private class InjectableCollector<Target: InjectableTarget>: SyntaxVisitor {
    var nodes = [Target]()
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
            if let injectable = try Target(decl: node) {
                nodes.append(injectable)
            }
        } catch {
            errors.append(error)
        }
    }
}

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

            XCTAssertEqual(d.parameters.map { $0.label }, ["Int", "Int?"])
            XCTAssertEqual(d.initializerCallExpr(["100", "nil"]).description,
                           ".init(userId: 100, optUserId: nil)")
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
        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Initializer>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class ClassUser: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: Dependency) {
                        fatalError()
                    }
                }
                struct StructUser: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: DIKit.Dependency) {
                        fatalError()
                    }
                }
                enum EnumUser: Injectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    init(dependency: Dependency) {
                        fatalError()
                    }
                }
                struct UserNotInjectable {
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
            XCTAssertEqual(collector.nodes.map { $0.outputType.name }, ["ClassUser", "StructUser", "EnumUser"])
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Initializer>()
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
            let collector = InjectableCollector<Declared.Injectable.Initializer>()
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
        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Factory>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class ClassUser: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> ClassUser {
                        fatalError()
                    }
                }
                struct StructUser: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> StructUser {
                        fatalError()
                    }
                }
                enum EnumUser: FactoryInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> EnumUser {
                        fatalError()
                    }
                }
                struct UserNotInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    static func makeInstance(dependency: Dependency) -> UserNotInjectable {
                        fatalError()
                    }
                }
                """
                })

            XCTAssertEqual(collector.nodes.count, 3)
            XCTAssertEqual(collector.nodes.map { $0.outputType.name }, ["ClassUser", "StructUser", "EnumUser"])
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Factory>()
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
            let collector = InjectableCollector<Declared.Injectable.Factory>()
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
            let collector = InjectableCollector<Declared.Injectable.Factory>()
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

    func testPropertyInjectable() throws {
        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class ClassUser: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency!
                }
                struct StructUser: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency!
                }
                enum EnumUser: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency!
                }
                struct UserNotInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency!
                }
                """
                })

            XCTAssertEqual(collector.nodes.count, 3)
            XCTAssertEqual(collector.nodes.map { $0.outputType.name }, ["ClassUser", "StructUser", "EnumUser"])
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Property.Error where error.reason == .propertyNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Dependency! { fatalError() }
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Property.Error where error.reason == .propertyNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }
                }

                extension User {
                    var dependency: Dependency! { fatalError() }
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Property.Error where error.reason == .propertyNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: PropertyInjectable {
                    struct Dependency {
                        let userId: Int
                        let optUserId: Int?
                        static var currentUser: User?
                    }

                    var dependency: Int!
                }
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Property.Error where error.reason == .propertyNotFound {
            XCTAssert(true)
        }

        do {
            let tempDir = try temporaryDirectory()
            let collector = InjectableCollector<Declared.Injectable.Property>()
            collector.visit(try makeSourceSyntax("Foo.swift", in: tempDir) {
                """
                class User: PropertyInjectable {}
                """
                })

            if let error = collector.errors.first {
                throw error
            }
            XCTFail()
        } catch let error as Declared.Injectable.Property.Error where error.reason == .associatedTypeNotFound {
            XCTAssert(true)
        }
    }

    static var allTests = [
        ("testDependency", testDependency),
        ("testInitializerInjectable", testInitializerInjectable),
        ("testFactoryInjectable", testFactoryInjectable),
        ("testPropertyInjectable", testPropertyInjectable)
    ]
}
