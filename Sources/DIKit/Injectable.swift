//
//  Injectable.swift
//  DIGenKit
//
//  Created by 林達也 on 2018/09/29.
//

public protocol Injectable {
    associatedtype Dependency
    init(dependency: Dependency)
}

public protocol FactoryMethodInjectable {
    associatedtype Dependency
    static func makeInstance(dependency: Dependency) -> Self
}

public protocol PropertyInjectable: class {
    associatedtype Dependency
    var dependency: Dependency! { get set }
}
