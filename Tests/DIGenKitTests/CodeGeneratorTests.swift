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
            import DIKit


            """
        }
        try makeFile("Foo.swift", in: tempDir) {
            """
            // comment
            import DIKits  // is not DIKit


            """
        }

        let generator = try CodeGenerator(path: tempDir.path)

        XCTAssertEqual(generator.targetFiles.count, 1)
    }

    static var allTests = [
        ("testCollectRelatedFiles", testCollectRelatedFiles)
    ]
}
