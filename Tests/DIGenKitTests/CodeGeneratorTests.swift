import XCTest
import SwiftSyntax
import Basic

@testable import DIGenKit

final class CodeGeneratorTests: XCTestCase {

    func testCollectRelatedFiles() throws {

        let tempDir = try temporaryDirectory()
        try makeFile("Bar.swift", in: tempDir) {
            """
            // comment
            import Foundation
            import DIKit

            struct A: Injectable {
                struct Dependency {
                    let letValue: Int
                    var varValue: Int
                    var varValue2: Int { return 1 }
                    static let staticLetValue: Int = 10
                    static var staticVarValue: Int = 20
                }
                init(dependency: Dependency) {}
            }

            private protocol TestResolver: Resolver {
            }

            """
        }
        try makeFile("Foo.swift", in: tempDir) {
            """
            // comment
            import DIKits  // is not DIKit


            """
        }

        let generator = try CodeGenerator(path: tempDir.path)
        XCTAssertEqual(try generator.generate(), """
        import Foundation
        import DIKit

        extension TestResolver {
            func resolveA() -> A {
                return provideA()
            }
        }
        """)
    }

    static var allTests = [
        ("testCollectRelatedFiles", testCollectRelatedFiles)
    ]
}
