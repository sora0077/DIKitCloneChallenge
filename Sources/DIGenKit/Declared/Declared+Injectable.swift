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

        fileprivate func hasProperty() -> Bool {
            return decl.helper.members?.members.lazy
                .compactMap { $0 as? VariableDeclSyntax }
                .contains(where: { prop in
                    let binding = prop.bindings.first
                    let type = binding?.typeAnnotation?.type

                    return prop.helper.isVar
                        && !prop.helper.isComputed
                        && (binding?.pattern as? IdentifierPatternSyntax)?.identifier.text == "dependency"
                        && type?.helper.name?.text == "Dependency"
                        && (type?.helper.isImplicitlyUnwrappedOptional ?? false)
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
        let outputType: Declared.SwiftType
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            do {
                guard let raw = try Declared.Injectable(decl: decl, as: "Injectable") else {
                    return nil
                }
                guard raw.hasInitializer(), let outputType = Declared.SwiftType(decl.helper.identifier) else {
                    throw Error(decl: decl, reason: .initializerNotFound)
                }
                self.outputType = outputType
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
                    return "Static method 'static makeInstance(dependency:)' declared in 'FactoryInjectable' is not found"
                case .associatedTypeNotFound:
                    return "Associated type 'Dependency' declared in 'FactoryInjectable' is not found"
                case .nonStructAssociatedType:
                    return "Associated type 'Dependency' must be a struct"
                case .cannotConstructAssociatedType:
                    return "Associated type 'Dependency' must be constructible"
                }
            }
        }

        var dependency: Dependency { return injectable.dependency }
        let outputType: Declared.SwiftType
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            do {
                guard let raw = try Declared.Injectable(decl: decl, as: "FactoryInjectable") else {
                    return nil
                }
                guard raw.hasFactory(), let outputType = Declared.SwiftType(decl.helper.identifier) else {
                    throw Error(decl: decl, reason: .staticMethodNotFound)
                }
                self.outputType = outputType
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

        struct Error: Swift.Error {
            enum Reason {
                case propertyNotFound
                case associatedTypeNotFound
                case nonStructAssociatedType
                case cannotConstructAssociatedType
            }

            let decl: DeclSyntax
            let reason: Reason

            var errorDescription: String? {
                switch reason {
                case .propertyNotFound:
                    return "Instance property 'dependency' declared in 'PropertyInjectable' is not found"
                case .associatedTypeNotFound:
                    return "Associated type 'Dependency' declared in 'PropertyInjectable' is not found"
                case .nonStructAssociatedType:
                    return "Associated type 'Dependency' must be a struct"
                case .cannotConstructAssociatedType:
                    return "Associated type 'Dependency' must be constructible"
                }
            }
        }

        var dependency: Dependency { return injectable.dependency }
        let outputType: Declared.SwiftType
        private let injectable: Declared.Injectable

        init?(decl: DeclSyntax) throws {
            do {
                guard let raw = try Declared.Injectable(decl: decl, as: "PropertyInjectable") else {
                    return nil
                }
                guard raw.hasProperty(), let outputType = Declared.SwiftType(decl.helper.identifier) else {
                    throw Error(decl: decl, reason: .propertyNotFound)
                }
                self.outputType = outputType
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
}

// MARK: -
extension Declared.Injectable {

    struct Dependency {

        enum Error: Swift.Error {
            case notFound
            case nonStructType
            case cannotConstruct
        }

        let parameters: [Declared.SwiftFunction.Parameter]
        let decl: StructDeclSyntax

        init(members: DeclListSyntax?) throws {
            func parseMemberType(_ member: DeclSyntax) throws -> Declared.SwiftFunction.Parameter? {
                guard let member = member as? VariableDeclSyntax else { return nil }
                if member.helper.isStatic || member.helper.isComputed { return nil }

                if member.helper.hasInitializer {
                    throw Error.cannotConstruct
                }
                guard
                    let binding = member.bindings.first,
                    let type = Declared.SwiftType(binding.typeAnnotation?.type) else {
                    throw Error.cannotConstruct
                }
                return .init(label: binding.pattern.description, type: type)
            }

            switch members?.first(where: { $0.helper.identifier?.text == "Dependency" }) {
            case let dependency as StructDeclSyntax:
                self.decl = dependency
                self.parameters = try dependency.members.members.compactMap(parseMemberType)
            case nil:
                throw Error.notFound
            default:
                throw Error.nonStructType
            }
        }

        func initializerCallExpr(_ args: [String]) -> FunctionCallExprSyntax {
            precondition(parameters.count == args.count)

            let count = args.count
            let arguments = (0..<count).map { i -> FunctionCallArgumentSyntax in
                let label = parameters[i].label
                let value = args[i]

                return SyntaxFactory.makeFunctionCallArgument(
                    label: SyntaxFactory.makeIdentifier(label),
                    colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                    expression: SyntaxFactory.makeIdentifierExpr(
                        identifier: SyntaxFactory.makeIdentifier(value),
                        declNameArguments: nil),
                    trailingComma: i == count - 1
                        ? nil : SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)))
            }

            return SyntaxFactory.makeFunctionCallExpr(
                calledExpression: SyntaxFactory.makeImplicitMemberExpr(
                    dot: SyntaxFactory.makePrefixPeriodToken(),
                    name: SyntaxFactory.makeIdentifier("init"),
                    declNameArguments: nil),
                leftParen: SyntaxFactory.makeLeftParenToken(),
                argumentList: SyntaxFactory.makeFunctionCallArgumentList(arguments),
                rightParen: SyntaxFactory.makeRightParenToken(),
                trailingClosure: nil)
        }
    }
}
