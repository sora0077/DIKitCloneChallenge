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
        try self.init(files: files(atPath: path, exclusions: exclusions))
    }

    public init(files: [AbsolutePath]) throws {
        targetFiles = try files
            .map { try SyntaxTreeParser.parse(URL(fileURLWithPath: $0.asString)) }
            .filter { DIKitImportVisitor($0).isImported }
    }

    public func generate() throws -> String {

        let collector = ResolverCollectVisitor()
        targetFiles.forEach(collector.visit)

        print(collector.imports)
        print(collector.resolvers)

        for resolver in collector.resolvers {
            try solve(with: resolver,
                      andInitializerInjectables: collector.initializers,
                      andFactoryInjectables: collector.factories,
                      andPropertyInjectables: collector.properties)
        }

        return ""
    }
}

private func files(atPath path: AbsolutePath, exclusions: [AbsolutePath]) throws -> [AbsolutePath] {

    if localFileSystem.exists(path) {
        if localFileSystem.isDirectory(path) {
            return try walk(path).filter { file in
                guard file.extension == "swift" else { return false }
                for exclude in exclusions where file.contains(exclude) {
                    return false
                }
                return true
            }
        } else if localFileSystem.isFile(path) {
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

private class ResolverCollectVisitor: SyntaxVisitor {

    let diagnosticEngine = DiagnosticEngine()

    private(set) var imports = Set<ImportDeclSyntax>()

    private(set) var resolvers = [Declared.Resolver]()
    private(set) var initializers = [Declared.Injectable.Initializer]()
    private(set) var factories = [Declared.Injectable.Factory]()
    private(set) var properties = [Declared.Injectable.Property]()

    override func visit(_ node: ImportDeclSyntax) {

        imports.insert(SyntaxFactory.makeImportDecl(
            attributes: node.attributes,
            modifiers: node.modifiers,
            importTok: node.importTok.withoutLeadingTrivia(),
            importKind: node.importKind,
            path: node.path))

        super.visit(node)
    }

    override func visit(_ node: StructDeclSyntax) {
        appendInjectable(node)
        super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) {
        appendInjectable(node)
        super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) {
        appendInjectable(node)
        super.visit(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) {
        do {
            if let resolver = try Declared.Resolver(decl: node) {
                resolvers.append(resolver)
            }
        } catch {
            diagnosticEngine.diagnose(.init(.warning, "\(error)"))
        }

        super.visit(node)
    }

    private func appendInjectable(_ node: DeclSyntax) {
        func record(_ body: () throws -> Void) {
            do {
                try body()
            } catch {
                diagnosticEngine.diagnose(.init(.warning, "\(error)"))
            }
        }
        record {
            if let injectable = try Declared.Injectable.Initializer(decl: node) {
                initializers.append(injectable)
            }
        }
        record {
            if let injectable = try Declared.Injectable.Factory(decl: node) {
                factories.append(injectable)
            }
        }
        record {
            if let injectable = try Declared.Injectable.Property(decl: node) {
                properties.append(injectable)
            }
        }
    }
}
