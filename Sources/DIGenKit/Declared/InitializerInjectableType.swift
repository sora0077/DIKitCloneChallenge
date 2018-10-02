//
//  InitializerInjectableType.swift
//  Basic
//
//  Created by 林達也 on 2018/09/30.
//

import Foundation
import SwiftSyntax

struct InitializerInjectableType {
    struct Error: LocalizedError {
        enum Reason {
            case protocolConformanceNotFound
            case associatedTypeNotFound
            case initializerNotFound
            case nonStructAssociatedType
        }

        let decl: DeclSyntax
        let reason: Reason

        var errorDescription: String? {
            switch reason {
            case .protocolConformanceNotFound:
                return "Type is not declared as conformer of 'Injectable'"
            case .associatedTypeNotFound:
                return "Associated type 'Dependency' declared in 'Injectable' is not found"
            case .initializerNotFound:
                return "Initializer 'init(dependency:)' declared in 'Injectable' is not found"
            case .nonStructAssociatedType:
                return "Associated type 'Dependency' must be a struct"
            }
        }
    }

    private let dependencyBuilder: DependencyBuilder

    init?(decl: DeclSyntax) throws {

        func error(_ reason: Error.Reason) -> Error {
            return Error(decl: decl, reason: reason)
        }

        func checkProtocolConformance(_ collection: InheritedTypeListSyntax?) throws {
            let found = collection?.contains(where: {
                $0.typeName.helper.name?.text == "Injectable"
            }) ?? false

            if !found {
                throw error(.protocolConformanceNotFound)
            }
        }

        try checkProtocolConformance(decl.helper.inheritanceClause?.inheritedTypeCollection)

        do {
            dependencyBuilder = try DependencyBuilder(members: decl.helper.members?.members)
        } catch DependencyBuilder.Error.associatedTypeNotFound {
            throw error(.associatedTypeNotFound)
        } catch DependencyBuilder.Error.nonStructAssociatedType {
            throw error(.nonStructAssociatedType)
        }

        print(try dependencyBuilder.buildInitializerCaller())
    }
}
