//
//  Declared+Injectable.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import SwiftSyntax

extension Declared {

    struct Injectable {

        struct Error: Swift.Error {
            enum Reason {
                case associatedTypeNotFound
                case initializerNotFound
                case nonStructAssociatedType
            }

            let decl: DeclSyntax
            let reason: Reason

            var errorDescription: String? {
                switch reason {
                case .associatedTypeNotFound:
                    return "Associated type 'Dependency' declared in 'Injectable' is not found"
                case .initializerNotFound:
                    return "Initializer 'init(dependency:)' declared in 'Injectable' is not found"
                case .nonStructAssociatedType:
                    return "Associated type 'Dependency' must be a struct"
                }
            }
        }

        let dependency: Dependency

        let decl: DeclSyntax

        fileprivate init?(decl: DeclSyntax, as name: String) throws {
            let adopted = decl.helper.inheritanceClause?.inheritedTypeCollection.contains(where: {
                $0.typeName.helper.name?.text == name
            }) ?? false
            guard adopted else { return nil }

            do {
                self.decl = decl
                self.dependency = try Dependency(members: decl.helper.members?.members) ?? {
                    throw Error(decl: decl, reason: .associatedTypeNotFound)
                }()
            } catch Dependency.Error.associatedTypeNotFound {
                throw Error(decl: decl, reason: .associatedTypeNotFound)
            } catch Dependency.Error.nonStructAssociatedType {
                throw Error(decl: decl, reason: .nonStructAssociatedType)
            }
        }
    }
}

extension Declared.Injectable {

    struct Initializer {

        var dependency: Dependency { return injectable.dependency }
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            guard let raw = try Declared.Injectable(decl: decl, as: "Injectable") else {
                return nil
            }
            self.injectable = raw
        }
    }

    struct Factory {

        var dependency: Dependency { return injectable.dependency }
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            guard let raw = try Declared.Injectable(decl: decl, as: "FactoryInjectable") else {
                return nil
            }
            self.injectable = raw
        }
    }

    struct Property {

        var dependency: Dependency { return injectable.dependency }
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            guard let raw = try Declared.Injectable(decl: decl, as: "PropertyInjectable") else {
                return nil
            }
            self.injectable = raw
        }
    }
}

extension Declared.Injectable {

    struct Dependency {

        enum Error: Swift.Error {
            case associatedTypeNotFound
            case nonStructAssociatedType
            case cannotConstructAssoicatedType
        }

        let dependedTypes: [Declared.SwiftType]
        let decl: StructDeclSyntax

        init?(members: DeclListSyntax?) throws {
            func parseMemberType(_ member: DeclSyntax) throws -> Declared.SwiftType? {
                guard let member = member as? VariableDeclSyntax else { return nil }
                if member.helper.isStatic || member.helper.isComputed { return nil }

                if member.helper.hasInitializer {
                    throw Error.cannotConstructAssoicatedType
                }
                guard let type = member.bindings.lazy.compactMap({ $0.typeAnnotation?.type }).first else {
                    throw Error.cannotConstructAssoicatedType
                }
                return Declared.SwiftType(type)
            }

            switch members?.first(where: { $0.helper.identifier?.text == "Dependency" }) {
            case let dependency as StructDeclSyntax:
                self.decl = dependency
                self.dependedTypes = try dependency.members.members.compactMap(parseMemberType)
            case nil:
                throw Error.associatedTypeNotFound
            default:
                throw Error.nonStructAssociatedType
            }
        }
    }
}
