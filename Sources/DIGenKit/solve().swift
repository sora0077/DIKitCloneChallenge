//
//  solve().swift
//  Basic
//
//  Created by 林達也 on 2018/10/09.
//

import SwiftSyntax

enum SolverError: Error {
    case unresolvableDependecyGraph
}

func solve(with resolver: Declared.Resolver,
           andInitializerInjectables initializerInjectables: [Declared.Injectable.Initializer] = [],
           andFactoryInjectables factoryInjectables: [Declared.Injectable.Factory] = [],
           andPropertyInjectables propertyInjectables: [Declared.Injectable.Property] = []) throws {

    var registeredTypes: [Declared.SwiftType] = []

    let providers = resolver.providedFunctions
        .map(Node.Declaration.provider)
        .filter { !registeredTypes.contains($0.targetType) }
    registeredTypes += providers.map { $0.targetType }

    let initializers = initializerInjectables
        .map(Node.Declaration.initializer)
        .filter { !registeredTypes.contains($0.targetType) }
    registeredTypes += initializers.map { $0.targetType }

    let factories = factoryInjectables
        .map(Node.Declaration.factory)
        .filter { !registeredTypes.contains($0.targetType) }
    registeredTypes += factories.map { $0.targetType }

    let allDeclarations = initializers + factories + providers
    var unresolvedDeclarations = allDeclarations
    var generatedResolveNodes: [Node] = []

    while !unresolvedDeclarations.isEmpty {
        var resolved = false
        for (index, declaration) in unresolvedDeclarations.enumerated() {
            guard let node = Node(declaration: declaration,
                                  allDeclarations: allDeclarations,
                                  availableNodes: generatedResolveNodes) else { continue }
            unresolvedDeclarations.remove(at: index)
            generatedResolveNodes.append(node)
            resolved = true
            break
        }

        if !resolved {
            throw SolverError.unresolvableDependecyGraph
        }
    }

    //
    //  --  --  --  --
    //
    let properties = propertyInjectables.map(Node.Declaration.properry)
    unresolvedDeclarations = properties
    var generatedInjectNodes: [Node] = []

    while !unresolvedDeclarations.isEmpty {
        var resolved = false
        for (index, declaration) in unresolvedDeclarations.enumerated() {
            guard let node = Node(declaration: declaration,
                                  allDeclarations: allDeclarations,
                                  availableNodes: generatedInjectNodes) else { continue }
            unresolvedDeclarations.remove(at: index)
            generatedInjectNodes.append(node)
            resolved = true
            break
        }

        if !resolved {
            throw SolverError.unresolvableDependecyGraph
        }
    }


    print(generatedResolveNodes)
    print("----------")
    print(unresolvedDeclarations)

    for node in generatedResolveNodes {
        print(ResolveMethodBuilder(node: node).build())
    }
}

//
// MARK: -
private struct Node {
    enum Declaration {
        case initializer(Declared.Injectable.Initializer)
        case factory(Declared.Injectable.Factory)
        case properry(Declared.Injectable.Property)

        case provider(Declared.Resolver.ProvidedFunction)

        var targetType: Declared.SwiftType {
            switch self {
            case .initializer(let injectable): return injectable.outputType
            case .factory(let injectable): return injectable.outputType
            case .properry(let injectable): return injectable.outputType
            case .provider(let f): return f.returnType
            }
        }

        var dependencies: [Declared.SwiftFunction.Parameter] {
            switch self {
            case .initializer(let injectable): return injectable.dependency.parameters
            case .factory(let injectable): return injectable.dependency.parameters
            case .properry(let injectable): return injectable.dependency.parameters
            case .provider(let f): return f.arguments
            }
        }
    }

    enum Dependency {
        case node(name: String, node: Node)
        case parameter(Declared.SwiftFunction.Parameter)
    }

    let declaration: Declaration
    let dependencies: [Dependency]

    init?(declaration: Declaration, allDeclarations: [Declaration], availableNodes: [Node]) {
        let allTargetTypes = Set(allDeclarations.map { $0.targetType })

        self.declaration = declaration
        self.dependencies = declaration.dependencies.compactMap { dependency in
            if let resolvableNode = availableNodes.first(where: { $0.declaration.targetType == dependency.type }) {
                return .node(name: dependency.label, node: resolvableNode)
            } else if !allTargetTypes.contains(dependency.type) {
                return .parameter(dependency)
            } else {
                return nil
            }
        }

        if dependencies.count != declaration.dependencies.count {
            // Could not fulfill all dependencies
            return nil
        }
    }

    var shallowDependencyNodes: [Node] {
        return dependencies.compactMap { dependency in
            if case .node(_, let node) = dependency {
                return node
            } else {
                return nil
            }
        }
    }

    var deepDependencyParameters: [Declared.SwiftFunction.Parameter] {
        return Node.recursiveDependencyParameters(of: self)
    }

    static func recursiveDependencyParameters(of node: Node) -> [Declared.SwiftFunction.Parameter] {
        let dependencyNodes = node.shallowDependencyNodes

        let dependencyParameter = node.dependencies.compactMap { dependency -> Declared.SwiftFunction.Parameter? in
            if case .parameter(let parameter) = dependency {
                return parameter
            } else {
                return nil
            }
        }

        let inheritedParameters = dependencyNodes.flatMap(Node.recursiveDependencyParameters(of:))

        return dependencyParameter + inheritedParameters
    }
}

private struct ResolveMethodBuilder {

    private let node: Node

    init(node: Node) {
        self.node = node
    }

    func build() -> FunctionDeclSyntax {

        func makeParameters() -> [FunctionParameterSyntax] {
            let parameters = node.deepDependencyParameters
            let count = parameters.count
            return parameters.enumerated().map { (i, param) in
                SyntaxFactory.makeFunctionParameter(
                    attributes: nil,
                    firstName: SyntaxFactory.makeIdentifier(param.label),
                    secondName: nil,
                    colon: SyntaxFactory.makeColonToken().withTrailingTrivia(.spaces(1)),
                    type: param.type.syntax,
                    ellipsis: nil,
                    defaultArgument: nil,
                    trailingComma: i != count - 1 ? SyntaxFactory.makeCommaToken().withTrailingTrivia(.spaces(1)) : nil)
            }
        }

        func makeBody() -> [CodeBlockItemSyntax] {
            return [SyntaxFactory.makeCodeBlockItem(item: SyntaxFactory.makeIdentifier("hoge").withLeadingTrivia(.spaces(4)), semicolon: nil)]
        }

        return SyntaxFactory.makeFunctionDecl(
            attributes: nil,
            modifiers: nil,
            funcKeyword: SyntaxFactory.makeFuncKeyword().withTrailingTrivia(.spaces(1)),
            identifier: SyntaxFactory.makeIdentifier("resolve\(node.declaration.targetType.name)"),
            genericParameterClause: nil,
            signature: SyntaxFactory.makeFunctionSignature(
                input: SyntaxFactory.makeParameterClause(
                    leftParen: SyntaxFactory.makeLeftParenToken(),
                    parameterList: SyntaxFactory.makeFunctionParameterList(
                        makeParameters()
                    ),
                    rightParen: SyntaxFactory.makeRightParenToken().withTrailingTrivia(.spaces(1))),
                throwsOrRethrowsKeyword: nil,
                output: SyntaxFactory.makeReturnClause(
                    arrow: SyntaxFactory.makeArrowToken().withTrailingTrivia(.spaces(1)),
                    returnType: node.declaration.targetType.syntax)),
            genericWhereClause: nil,
            body: SyntaxFactory.makeCodeBlock(
                leftBrace: SyntaxFactory.makeLeftBraceToken()
                    .withLeadingTrivia(.spaces(1))
                    .withTrailingTrivia(.newlines(1)),
                statements: SyntaxFactory.makeCodeBlockItemList(
                    makeBody()
                ),
                rightBrace: SyntaxFactory.makeRightBraceToken().withLeadingTrivia(.newlines(1))))
    }
}
