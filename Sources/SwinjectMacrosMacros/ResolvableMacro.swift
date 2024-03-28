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
        guard let initDecl = declaration.as(InitializerDeclSyntax.self) else {
            throw Error.nonInitializer
        }
        let params = try initDecl.signature.parameterClause.parameters.map { paramSyntax in
            let type = try extractType(typeSyntax: paramSyntax.type)
            return Param(name: paramSyntax.firstName.text, type: type)
        }
        
        let paramsResolved = params.map { param in
            return "\(param.name): resolver.resolve(\(param.type).self)!"
        }
        let paramsString = paramsResolved.joined(separator: ",\n")
        
        return [
           """
           static func make(resolver: Resolver) -> Self {
                return .init(
                    \(raw: paramsString)
                )
           }
           """
           ]
    }
    
    private static func extractType(typeSyntax: TypeSyntax) throws -> String {
        if let type = typeSyntax.as(IdentifierTypeSyntax.self) {
            return type.name.text
        } else if let type = typeSyntax.as(AttributedTypeSyntax.self) {
            return try extractType(typeSyntax: type.baseType)
        } else if let type = typeSyntax.as(FunctionTypeSyntax.self) {
            return "(\(type.description))"
        }
        throw Error.invalidParamType(typeSyntax.description)
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
