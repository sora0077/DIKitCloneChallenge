//
//  Declared+Injectable.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/06.
//

import SwiftSyntax

extension Declared {

    struct Injectable {
        let dependency: Dependency
        let decl: DeclSyntax

        fileprivate init?(decl: DeclSyntax, as name: String) throws {
            let adopted = decl.helper.inheritanceClause?.inheritedTypeCollection.contains(where: {
                $0.typeName.helper.name?.text == name
            }) ?? false
            guard adopted else { return nil }

            self.decl = decl
            self.dependency = try Dependency(members: decl.helper.members?.members)
        }

        fileprivate func hasInitializer() -> Bool {
            return decl.helper.members?.members.lazy
                .compactMap { $0 as? InitializerDeclSyntax }
                .flatMap { $0.parameters.parameterList }
                .contains(where: { f in
                    return f.firstName?.text == "dependency"
                        && f.type?.helper.name?.text == "Dependency"
                }) ?? false
        }

        fileprivate func hasFactory() -> Bool {
            return decl.helper.members?.members.lazy
                .compactMap { $0 as? FunctionDeclSyntax }
                .contains(where: { f in
                    let input = f.signature.input.parameterList.first
                    let output = f.signature.output?.returnType

                    return f.identifier.text == "makeInstance"
                        && input?.firstName?.text == "dependency"
                        && input?.type?.helper.name?.text == "Dependency"
                        && output?.helper.name?.text == decl.helper.identifier?.text
                }) ?? false
        }
    }
}

extension Declared.Injectable {

    // MARK: -
    struct Initializer {

        struct Error: Swift.Error {
            enum Reason {
                case initializerNotFound
                case associatedTypeNotFound
                case nonStructAssociatedType
                case cannotConstructAssociatedType
            }

            let decl: DeclSyntax
            let reason: Reason

            var errorDescription: String? {
                switch reason {
                case .initializerNotFound:
                    return "Initializer 'init(dependency:)' declared in 'Injectable' is not found"
                case .associatedTypeNotFound:
                    return "Associated type 'Dependency' declared in 'Injectable' is not found"
                case .nonStructAssociatedType:
                    return "Associated type 'Dependency' must be a struct"
                case .cannotConstructAssociatedType:
                    return "Associated type 'Dependency' must be constructible"
                }
            }
        }

        var dependency: Dependency { return injectable.dependency }
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            do {
                guard let raw = try Declared.Injectable(decl: decl, as: "Injectable") else {
                    return nil
                }
                guard raw.hasInitializer() else {
                    throw Error(decl: decl, reason: .initializerNotFound)
                }
                self.injectable = raw
            } catch Dependency.Error.cannotConstruct {
                throw Error(decl: decl, reason: .cannotConstructAssociatedType)
            } catch Dependency.Error.notFound {
                throw Error(decl: decl, reason: .associatedTypeNotFound)
            } catch Dependency.Error.nonStructType {
                throw Error(decl: decl, reason: .nonStructAssociatedType)
            }
        }
    }

    // MARK: -
    struct Factory {

        struct Error: Swift.Error {
            enum Reason {
                case staticMethodNotFound
                case associatedTypeNotFound
                case nonStructAssociatedType
                case cannotConstructAssociatedType
            }

            let decl: DeclSyntax
            let reason: Reason

            var errorDescription: String? {
                switch reason {
                case .staticMethodNotFound:
                    return "Static method 'static makeInstance(dependency:)' declared in 'Injectable' is not found"
                case .associatedTypeNotFound:
                    return "Associated type 'Dependency' declared in 'Injectable' is not found"
                case .nonStructAssociatedType:
                    return "Associated type 'Dependency' must be a struct"
                case .cannotConstructAssociatedType:
                    return "Associated type 'Dependency' must be constructible"
                }
            }
        }

        var dependency: Dependency { return injectable.dependency }
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            do {
                guard let raw = try Declared.Injectable(decl: decl, as: "FactoryInjectable") else {
                    return nil
                }
                guard raw.hasFactory() else {
                    throw Error(decl: decl, reason: .staticMethodNotFound)
                }
                self.injectable = raw
            } catch Dependency.Error.cannotConstruct {
                throw Error(decl: decl, reason: .cannotConstructAssociatedType)
            } catch Dependency.Error.notFound {
                throw Error(decl: decl, reason: .associatedTypeNotFound)
            } catch Dependency.Error.nonStructType {
                throw Error(decl: decl, reason: .nonStructAssociatedType)
            }
        }
    }

    // MARK: -
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

// MARK: -
extension Declared.Injectable {

    struct Dependency {

        enum Error: Swift.Error {
            case notFound
            case nonStructType
            case cannotConstruct
        }

        let dependedTypes: [Declared.SwiftType]
        let decl: StructDeclSyntax

        init(members: DeclListSyntax?) throws {
            func parseMemberType(_ member: DeclSyntax) throws -> Declared.SwiftType? {
                guard let member = member as? VariableDeclSyntax else { return nil }
                if member.helper.isStatic || member.helper.isComputed { return nil }

                if member.helper.hasInitializer {
                    throw Error.cannotConstruct
                }
                guard let type = member.bindings.lazy.compactMap({ $0.typeAnnotation?.type }).first else {
                    throw Error.cannotConstruct
                }
                return Declared.SwiftType(type)
            }

            switch members?.first(where: { $0.helper.identifier?.text == "Dependency" }) {
            case let dependency as StructDeclSyntax:
                self.decl = dependency
                self.dependedTypes = try dependency.members.members.compactMap(parseMemberType)
            case nil:
                throw Error.notFound
            default:
                throw Error.nonStructType
            }
        }
    }
}
