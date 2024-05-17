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
        let hints = try parseHints(attributes: initDecl.attributes)
        let params = try initDecl.signature.parameterClause.parameters.map { paramSyntax in
            let type = try extractType(typeSyntax: paramSyntax.type)
            let name = paramSyntax.firstName.text
            
            return Param(
                name: name,
                type: type,
                isArgument: hints.isArgument(name: name),
                defaultValue: extractDefault(paramSyntax: paramSyntax)
            )
        }
        
        let paramsResolved = params.map { param in
            return resolveCall(param: param)
        }
        let paramsString = paramsResolved.joined(separator: ",\n")
        var makeArguments = ["resolver: Resolver"]
        for param in params {
            if param.isArgument {
                makeArguments.append("\(param.name): \(param.type.name)")
            }
        }
        
        let makeArgumentsString = makeArguments.joined(separator: ", ")
        
        return [
           """
           static func make(\(raw: makeArgumentsString)) -> Self {
                return .init(
                    \(raw: paramsString)
                )
           }
           """
           ]
    }
    
    private static func resolveCall(param: Param) -> String {
        if param.isArgument {
            return "\(param.name): \(param.name)"
        }
        if let defaultValue = param.defaultValue {
            return "\(param.name): resolver.resolve(\(param.type.name).self) ?? \(defaultValue)"
        }
        return "\(param.name): resolver.resolve(\(param.type.name).self)!"
    }
    
    private static func extractType(typeSyntax: TypeSyntax) throws -> TypeInformation {
        if let type = typeSyntax.as(IdentifierTypeSyntax.self) {
            return TypeInformation(name: type.name.text)
        } else if let type = typeSyntax.as(AttributedTypeSyntax.self) {
            let isArgument = type.attributes.contains { element in
                return element.description.trimmingCharacters(in: .whitespaces) == "@Argument"
            }
            let baseType = try extractType(typeSyntax: type.baseType)
            return TypeInformation(name: baseType.name)
        } else if let type = typeSyntax.as(FunctionTypeSyntax.self) {
            return TypeInformation(name: "(\(type.description))")
        }
        throw Error.invalidParamType(typeSyntax.description)
    }
    
    private static func extractDefault(paramSyntax: FunctionParameterSyntax) -> String? {
        guard let defaultValue = paramSyntax.defaultValue else {
            return nil
        }
        return defaultValue.description.replacingOccurrences(of: "= ", with: "")
    }
    
    private static func parseHints(attributes: AttributeListSyntax) throws -> HintContainer {
        let hints = try attributes.compactMap { element in
            switch element {
            case let .attribute(attribute):
                return try hint(attribute: attribute)
            case .ifConfigDecl:
                return nil
            }
        }
        return HintContainer(hints: hints)
    }
    
    private static func hint(attribute: AttributeSyntax) throws -> Hint? {
        guard let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text else {
            return nil
        }
        print(name)
        guard let argumentList = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }
        if name == "Argument" {
            guard let argument = argumentList.first else {
                throw Error.expectedArgumentName
            }
            guard let expressions = argument.expression.as(StringLiteralExprSyntax.self) else {
                throw Error.expectedExpression
            }
            let name = expressions.segments.first?.trimmedDescription
            return .argument(name: name!.replacingOccurrences(of: "\"", with: ""))
        }
        
        return nil
    }
}

private extension ResolvableMacro {
    struct Param {
        let name: String
        let type: TypeInformation
        let isArgument: Bool
        let defaultValue: String?
    }
    
    struct TypeInformation {
        let name: String
        
        init(name: String) {
            self.name = name
        }
    }
    
    enum Hint {
        case argument(name: String)
    }
    
    private struct HintContainer {
        let hints: [Hint]
        
        func isArgument(name: String) -> Bool {
            for hint in hints {
                if case .argument(let argumentName) = hint, name == argumentName {
                    return true
                }
            }
            return false
        }
        
    }
    
    enum Error: LocalizedError {
        case nonInitializer
        case expectedArgumentName
        case expectedExpression
        case invalidParamType(String)
        
        var errorDescription: String? {
            switch self {
            case .nonInitializer:
                return "@Resolvable can only be used on init declarations"
            case let .invalidParamType(string):
                return "Unexpected parameter type: \(string)"
            case .expectedArgumentName:
                return "Expected Argument name"
            case .expectedExpression:
                return "Expected expression"
            }
        }
    }
}
