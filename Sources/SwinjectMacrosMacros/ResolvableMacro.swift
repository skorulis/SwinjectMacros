//  Created by Alexander Skorulis on 28/3/2024.

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ResolvableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        print(declaration)
        guard let initDecl = declaration.as(InitializerDeclSyntax.self) else {
            throw Error.nonInitializer
        }
        let params = try initDecl.signature.parameterClause.parameters.map { paramSyntax in
            guard let typeID = paramSyntax.type.as(IdentifierTypeSyntax.self) else {
                throw Error.invalidParamType(paramSyntax.type.description)
            }
            let type = typeID.name.text
            return Param(name: paramSyntax.firstName.text, type: type)
        }
        
        print(params)
        return [
           """
           static func make(resolver: Resolver) -> Self {
                return .init(
           
                )
           }
           """
           ]
    }
}

private extension ResolvableMacro {
    private struct Param {
        let name: String
        let type: String
    }
    
    enum Error: LocalizedError {
        case nonInitializer
        case invalidParamType(String)
        
        var errorDescription: String? {
            switch self {
            case .nonInitializer:
                return "@Resolvable can only be used on init declarations"
            case let .invalidParamType(string):
                return "Unexpected parameter type: \(string)"
            }
        }
    }
}
