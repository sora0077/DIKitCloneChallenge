//
//  ProviderMethod.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/02.
//

import Foundation
import SwiftSyntax

struct ProviderMethod {
    struct Error: LocalizedError {
        enum Reason {
            case nonResolverTypeMethod
            case returnTypeNotFound
            case nonInstanceMethod
            case nonMethod
        }

        let decl: DeclSyntax
        let reason: Reason

        var errorDescription: String? {
            switch reason {
            case .nonResolverTypeMethod:
                return "Type does not conform to 'Resolver' protocol"
            case .returnTypeNotFound:
                return "Provide method must return non-void type"
            case .nonInstanceMethod:
                return "Provide method must not be static"
            case .nonMethod:
                return "Provide method must not be an initalizer"
            }
        }
    }

    let decl: FunctionDeclSyntax

    private init?(decl: DeclSyntax) throws {

        func error(_ reason: Error.Reason) -> Error {
            return Error(decl: decl, reason: reason)
        }

        guard let decl = decl as? FunctionDeclSyntax else {
            return nil
        }

        guard decl.helper.identifier?.text.starts(with: "provide") ?? false else {
            return nil
        }

        guard decl.signature.output?.returnType.helper.name?.text != "Void" else {
            throw error(.returnTypeNotFound)
        }

        self.decl = decl
    }

    static func providerMethods(in decl: ProtocolDeclSyntax) throws -> [ProviderMethod] {

        func checkProtocolConformance(_ collection: InheritedTypeListSyntax?) throws {
            let found = collection?.contains(where: {
                $0.typeName.helper.name?.text == "Resolver"
            }) ?? false

            if !found {
                throw Error(decl: decl, reason: .nonResolverTypeMethod)
            }
        }

        try checkProtocolConformance(decl.helper.inheritanceClause?.inheritedTypeCollection)

        return try decl.members.members.compactMap(ProviderMethod.init(decl:))
    }
}
