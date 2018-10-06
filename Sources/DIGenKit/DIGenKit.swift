import SwiftSyntax

protocol DIGenKitError: Error {
    var decl: DeclSyntax { get }
}
