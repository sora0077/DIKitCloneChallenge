//
//  CodeGenerator.swift
//  Basic
//
//  Created by 林達也 on 2018/09/29.
//

import Foundation
import SwiftSyntax
import Basic

public class CodeGenerator {

    let targetFiles: [SourceFileSyntax]

    public convenience init(path: AbsolutePath, exclusions: [AbsolutePath] = []) throws {
        try self.init(path: path, exclusions: exclusions, in: localFileSystem)
    }

    convenience init(path: AbsolutePath, exclusions: [AbsolutePath] = [], in filesystem: FileSystem) throws {
        try self.init(files: files(atPath: path, exclusions: exclusions, in: filesystem))
    }

    public init(files: [AbsolutePath]) throws {
        targetFiles = try files
            .map { try SyntaxTreeParser.parse(URL(fileURLWithPath: $0.asString)) }
            .filter { DIKitImportVisitor($0).isImported }
    }

    public func generate() throws -> String {
        return ""
    }
}

private func files(
    atPath path: AbsolutePath,
    exclusions: [AbsolutePath],
    in filesystem: FileSystem) throws -> [AbsolutePath] {

    if filesystem.exists(path) {
        if filesystem.isDirectory(path) {
            return try walk(path, fileSystem: filesystem).filter { file in
                guard file.extension == "swift" else { return false }
                for exclude in exclusions where file.contains(exclude) {
                    return false
                }
                return true
            }
        } else if filesystem.isFile(path) {
            return [path]
        }
    }
    return []
}

private class DIKitImportVisitor: SyntaxVisitor {

    private(set) var isImported: Bool = false

    init(_ syntax: SourceFileSyntax) {
        super.init()
        visit(syntax)
    }

    override func visit(_ node: ImportDeclSyntax) {

        if !isImported && node.path.first?.name.text == "DIKit" {
            isImported = true
        }

        super.visit(node)
    }
}
