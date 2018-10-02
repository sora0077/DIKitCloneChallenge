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

        print(collector.extensions)

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

    private(set) var imports = Set<ImportDeclSyntax>()

    private(set) var resolvers = Set<ProtocolDeclSyntax>()

    private(set) var extensions = Set<ExtensionDeclSyntax>()

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

        do {
            let type = try InitializerInjectableType(decl: node)
        } catch {

        }

        super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) {

        super.visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) {

        super.visit(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) {

        _ = try? ProviderMethod.providerMethods(in: node)

        let found = node.inheritanceClause?.inheritedTypeCollection.contains(where: {
            switch $0.typeName {
            case let typeName as SimpleTypeIdentifierSyntax:
                return typeName.name.text == "Resolver"
            case let typeName as MemberTypeIdentifierSyntax:
                return typeName.name.text == "Resolver"
            default:
                return false
            }
        })

        if found ?? false {
            resolvers.insert(SyntaxFactory.makeProtocolDecl(
                attributes: node.attributes,
                modifiers: node.modifiers,
                protocolKeyword: node.protocolKeyword,
                identifier: node.identifier,
                inheritanceClause: node.inheritanceClause,
                genericWhereClause: node.genericWhereClause,
                members: node.members))

            extensions.insert(SyntaxFactory.makeExtensionDecl(
                attributes: nil,
                modifiers: nil,
                extensionKeyword: SyntaxFactory.makeExtensionKeyword().withTrailingTrivia(.spaces(1)),
                extendedType: SyntaxFactory.makeTypeIdentifier(node.identifier.text),
                inheritanceClause: nil,
                genericWhereClause: nil,
                members: SyntaxFactory.makeMemberDeclBlock(
                    leftBrace: SyntaxFactory.makeLeftBraceToken().withLeadingTrivia(.spaces(1)),
                    members: SyntaxFactory.makeDeclList([

                    ]),
                    rightBrace: SyntaxFactory.makeRightBraceToken())))
        }

        super.visit(node)
    }
}
