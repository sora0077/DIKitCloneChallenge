import Foundation
import Basic
import SwiftSyntax

func getInput(_ file: String) -> URL {
    var dir = targetDirectory()
    for comp in file.components(separatedBy: "/") {
        dir = dir.appending(component: comp)
    }
    return dir.asURL
}

@discardableResult
func makeFile(_ file: String, in dir: TemporaryDirectory, content: () -> String) throws -> AbsolutePath {
    let filePath = dir.path.appending(component: file)

    try localFileSystem.writeFileContents(filePath, body: { stream in
        stream <<< content()
    })

    return filePath
}

func makeSourceSyntax(_ file: String, in dir: TemporaryDirectory, content: () -> String) throws -> SourceFileSyntax {
    return try SyntaxTreeParser.parse(makeFile(file, in: dir, content: content).asURL)
}

func temporaryDirectory() throws -> TemporaryDirectory {
    return try TemporaryDirectory(dir: targetDirectory(), removeTreeOnDeinit: true)
}

func targetDirectory() -> AbsolutePath {
    return AbsolutePath(#file).parentDirectory.appending(component: "Inputs")
}

extension AbsolutePath {
    var asURL: URL { return URL(fileURLWithPath: asString) }
}
