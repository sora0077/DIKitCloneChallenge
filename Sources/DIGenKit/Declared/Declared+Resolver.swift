//
//  Declared+Resolver.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import Foundation
import SwiftSyntax

extension Declared {

    struct Resolver {
        let providedFunctions: [ProvidedFunction]
        let decl: ProtocolDeclSyntax

        init?(decl: ProtocolDeclSyntax) throws {
            let found = decl.helper.inheritanceClause?.inheritedTypeCollection.contains(where: {
                $0.typeName.helper.name?.text == "Resolver"
            }) ?? false

            if !found {
                return nil
            }

            self.providedFunctions = try decl.members.members
                .compactMap { $0 as? FunctionDeclSyntax }
                .compactMap(ProvidedFunction.init(decl:))
            self.decl = decl
        }
    }
}

extension Declared.Resolver {

    struct ProvidedFunction {

        struct Error: LocalizedError {
            enum Reason {
                case returnTypeNotFound
                case nonInstanceMethod
                case nonMethod
            }

            let decl: DeclSyntax
            let reason: Reason

            var errorDescription: String? {
                switch reason {
                case .returnTypeNotFound:
                    return "Provide method must return non-void type"
                case .nonInstanceMethod:
                    return "Provide method must not be static"
                case .nonMethod:
                    return "Provide method must not be an initalizer"
                }
            }
        }

        let methodName: String
        let arguments: [Declared.SwiftFunction.Parameter]
        let returnType: Declared.SwiftType

        let decl: FunctionDeclSyntax

        init?(decl: FunctionDeclSyntax) throws {
            guard decl.helper.identifier?.text.starts(with: "provide") ?? false else {
                return nil
            }

            guard let returnType = Declared.SwiftType(decl.signature.output?.returnType), returnType.name != "Void" else {
                throw Error(decl: decl, reason: .returnTypeNotFound)
            }

            guard !decl.helper.isStatic else {
                throw Error(decl: decl, reason: .nonInstanceMethod)
            }

            self.decl = decl
            self.methodName = decl.identifier.text
            self.returnType = returnType
            self.arguments = decl.signature.input.parameterList.compactMap {
                guard let label = $0.firstName?.text, let type = Declared.SwiftType($0.type) else { return nil }
                return .init(label: label, type: type)
            }
        }
    }
}
