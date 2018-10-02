//
//  SwiftSyntaxHelper.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/01.
//

import SwiftSyntax

struct SyntaxHelper<T> {
    fileprivate let base: T

    fileprivate init(base: T) { self.base = base }
}

//
// MARK: -
extension TypeSyntax {
    var helper: SyntaxHelper<TypeSyntax> { return SyntaxHelper(base: self) }
}

extension DeclSyntax {
    var helper: SyntaxHelper<DeclSyntax> { return SyntaxHelper(base: self) }
}

extension VariableDeclSyntax {
    var helper: SyntaxHelper<VariableDeclSyntax> { return SyntaxHelper(base: self) }
}

extension FunctionDeclSyntax {
    var helper: SyntaxHelper<FunctionDeclSyntax> { return SyntaxHelper(base: self) }
}

// MARK: -
extension SyntaxHelper where T == TypeSyntax {

    var name: TokenSyntax? {
        switch base {
        case let base as SimpleTypeIdentifierSyntax:
            return base.name

        case let base as MemberTypeIdentifierSyntax:
            return base.name

        default:
            assertionFailure("\(base)")
            return nil
        }
    }
}

extension SyntaxHelper where T == DeclSyntax {

    var identifier: TokenSyntax? {
        switch base {
        case let base as StructDeclSyntax:
            return base.identifier

        case let base as EnumDeclSyntax:
            return base.identifier

        case let base as ClassDeclSyntax:
            return base.identifier

        case let base as ProtocolDeclSyntax:
            return base.identifier

        case let base as OperatorDeclSyntax:
            return base.identifier

        case let base as FunctionDeclSyntax:
            return base.identifier

        default:
            assertionFailure("\(base)")
            return nil
        }
    }

    var inheritanceClause: TypeInheritanceClauseSyntax? {
        switch base {
        case let base as StructDeclSyntax:
            return base.inheritanceClause

        case let base as EnumDeclSyntax:
            return base.inheritanceClause

        case let base as ClassDeclSyntax:
            return base.inheritanceClause

        case let base as ProtocolDeclSyntax:
            return base.inheritanceClause

        default:
            assertionFailure("\(base)")
            return nil
        }
    }

    var members: MemberDeclBlockSyntax? {
        switch base {
        case let base as StructDeclSyntax:
            return base.members

        case let base as EnumDeclSyntax:
            return base.members

        case let base as ClassDeclSyntax:
            return base.members

        default:
            assertionFailure("\(base)")
            return nil
        }
    }
}

extension SyntaxHelper where T == FunctionDeclSyntax {

    var isStatic: Bool {
        return base.modifiers?.contains(where: { $0.name.text == "static" }) ?? false
    }
}

extension SyntaxHelper where T == VariableDeclSyntax {

    var isStatic: Bool {
        return base.modifiers?.contains(where: { $0.name.text == "static" }) ?? false
    }

    var isVar: Bool {
        return base.letOrVarKeyword.text == "var"
    }

    var isLet: Bool {
        return base.letOrVarKeyword.text == "let"
    }

    var isComputed: Bool {
        return base.bindings.contains(where: { $0.accessor != nil })
    }
}
