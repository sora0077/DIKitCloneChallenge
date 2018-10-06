//
//  Declared.swift
//  Basic
//
//  Created by 林達也 on 2018/10/04.
//

enum Declared {}

import SwiftSyntax

extension Declared {

    struct SwiftType: Hashable {

        let name: String
        let syntax: TypeSyntax

        init?(_ syntax: TypeSyntax) {
            guard let name = syntax.helper.name?.text else { return nil }
            self.name = name + (syntax.helper.isOptional ? "?" : "")
            self.syntax = syntax
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        static func == (lhs: SwiftType, rhs: SwiftType) -> Bool {
            return lhs.name == rhs.name
        }
    }
}
