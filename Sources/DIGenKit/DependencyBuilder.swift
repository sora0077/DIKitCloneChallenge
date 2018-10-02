//
//  DependencyBuilder.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/01.
//

import SwiftSyntax

struct DependencyBuilder {
    enum Error: Swift.Error {
        case associatedTypeNotFound
        case nonStructAssociatedType
    }

    private let dependency: StructDeclSyntax

    init(members: DeclListSyntax?) throws {

        func dependencyDecl() throws -> StructDeclSyntax {
            let dependency = members?.first(where: { $0.helper.identifier?.text == "Dependency" })

            switch dependency {
            case let dependency as StructDeclSyntax:
                return dependency

            case nil:
                throw Error.associatedTypeNotFound

            default:
                throw Error.nonStructAssociatedType
            }
        }

        dependency = try dependencyDecl()
    }

    // .init(a: a, b: b, c: c)
    func buildInitializerCaller() throws {
        let a = dependency.members.members
            .lazy
            .compactMap {
                $0 as? VariableDeclSyntax
            }
            .compactMap {
                $0.helper.isStatic || $0.helper.isComputed ? nil : $0
            }
    }
}
