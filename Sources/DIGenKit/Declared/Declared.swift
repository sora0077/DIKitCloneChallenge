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

        init?(_ syntax: TypeSyntax?) {
            guard let syntax = syntax else { return nil }
            guard let name = syntax.helper.name?.text else { return nil }
            self.name = name + (syntax.helper.isOptional ? "?" : "")
            self.syntax = syntax
        }

        init?(_ syntax: TokenSyntax?) {
            guard let syntax = syntax else { return nil }
            self.init(SyntaxFactory.makeTypeIdentifier(syntax.text))
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        static func == (lhs: SwiftType, rhs: SwiftType) -> Bool {
            return lhs.name == rhs.name
        }
    }

    struct SwiftFunction: Hashable {
        struct Parameter: Hashable {
            let label: String
            let type: SwiftType
        }

        let identifier: String
        let parameters: [Parameter]
        let returnType: SwiftType
    }
}
