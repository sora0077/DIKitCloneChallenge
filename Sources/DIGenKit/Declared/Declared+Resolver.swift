//
//  Declared+Resolver.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import SwiftSyntax

extension Declared {

    struct Resolver {
        let providedFunctions: [ProvidedFunction]

        let decl: ProtocolDeclSyntax

        init?(decl: ProtocolDeclSyntax) throws {
            return nil
        }
    }
}

extension Declared.Resolver {

    struct ProvidedFunction {

        let argumentTypes: [Declared.SwiftType]
        let returnType: Declared.SwiftType

        let decl: FunctionDeclSyntax

        init?(decl: FunctionDeclSyntax) throws {
            return nil
        }
    }

    struct ResolvedFunction {

    }
}
