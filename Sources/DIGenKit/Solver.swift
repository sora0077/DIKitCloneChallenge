//
//  Solver.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/10/05.
//

struct Solver<Content: Hashable> {

    enum Error: Swift.Error {
        case circularDependency([(Content, deps: [Content])])
    }

    private struct Node {
        let target: Content
        let deps: [Content]
    }

    func solve(_ nodes: [(Content, deps: [Content])]) throws -> [(target: Content, deps: [Content])] {
        let nodes = nodes.map(Node.init)

        var nodeMap: [Content: Node] = [:]
        var nodeDependencies: [Content: Set<Content>] = [:]

        for node in nodes {
            nodeMap[node.target] = node
            nodeDependencies[node.target] = Set(node.deps)
        }

        var resolved: [Node] = []
        while !nodeDependencies.isEmpty {
            var ready: Set<Content> = []
            for (target, deps) in nodeDependencies where deps.isEmpty {
                ready.insert(target)
            }

            if ready.isEmpty {
                let nodes = nodeDependencies
                    .compactMap { key, _ in nodeMap[key] }
                    .map { ($0.target, $0.deps) }
                throw Error.circularDependency(nodes)
            }

            for target in ready {
                nodeDependencies[target] = nil
                if let node = nodeMap[target] {
                    resolved.append(node)
                }
            }

            for (target, deps) in nodeDependencies {
                nodeDependencies[target] = deps.subtracting(ready)
            }
        }

        return resolved.map { ($0.target, $0.deps) }
    }
}
