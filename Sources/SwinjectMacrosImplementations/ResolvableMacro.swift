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
        guard let resolverTypeArg = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause?.arguments.first else {
            throw Error.missingResolverType
        }
        let resolverType = resolverTypeArg.description
        var arguments: [String] = []
        var names: [String: String] = [:]
        if let nodeArgs = node.arguments?.as(LabeledExprListSyntax.self) {
            arguments = parseArguments(node: nodeArgs)
            names = parseNames(node: nodeArgs)
        }
        
        guard let initDecl = declaration.as(InitializerDeclSyntax.self) else {
            throw Error.nonInitializer
        }
        let params = try initDecl.signature.parameterClause.parameters.map { paramSyntax in
            let type = try extractType(typeSyntax: paramSyntax.type)
            let name = paramSyntax.firstName.text
            let hint: ParamHint?
            if arguments.contains(name) {
                hint = .argument
            } else if let serviceName = names[name] {
                hint = .named(serviceName)
            } else {
                hint = nil
            }
            
            return Param(
                name: name,
                type: type,
                hint: hint,
                defaultValue: extractDefault(paramSyntax: paramSyntax)
            )
        }
        
        let paramsResolved = params.map { param in
            return resolveCall(param: param)
        }
        let paramsString = paramsResolved.joined(separator: ",\n")
        var makeArguments = ["resolver: \(resolverType)"]
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
        return param.resolveCall
    }
    
    private static func parseArguments(node: LabeledExprListSyntax) -> [String] {
        guard let args = node.first(where: { $0.label?.description == "arguments"})?.expression.as(ArrayExprSyntax.self)?.elements else {
            return []
        }
        return args.compactMap { arrayElement in
            return arrayElement.expression.as(StringLiteralExprSyntax.self)?.textContent
        }
    }
    
    static func parseNames(node: LabeledExprListSyntax) -> [String: String] {
        guard let names = node.first(where: { $0.label?.description == "names"})?
            .expression.as(DictionaryExprSyntax.self)?.content
            .as(DictionaryElementListSyntax.self)
        else {
            return [:]
        }
        var result: [String: String] = [:]
        for element in names {
            guard let key = element.key.as(StringLiteralExprSyntax.self)?.textContent,
                  let value = element.value.as(StringLiteralExprSyntax.self)?.textContent else {
                continue
            }
            result[key] = value
        }
        
        return result
    }
    
    private static func extractType(typeSyntax: TypeSyntax) throws -> TypeInformation {
        if let type = typeSyntax.as(IdentifierTypeSyntax.self) {
            return TypeInformation(name: type.name.text)
        } else if let type = typeSyntax.as(AttributedTypeSyntax.self) {
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
    
}

private extension ResolvableMacro {
    struct Param {
        let name: String
        let type: TypeInformation
        let hint: ParamHint?
        let defaultValue: String?
        
        var isArgument: Bool { hint == .argument }
        
        var resolveCall: String {
            let knitCallName = TypeNamer.computedIdentifierName(type: type.name)
            if let defaultValue {
                return "\(name): \(defaultValue)"
            } else if let hint, case let ParamHint.named(serviceName) = hint {
                return "\(name): resolver.\(knitCallName)(name: .\(serviceName))"
            } else {
                return "\(name): resolver.\(knitCallName)()"
            }
        }
    }
    
    struct TypeInformation {
        let name: String
        
        init(name: String) {
            self.name = name
        }
    }
    
    enum ParamHint: Equatable {
        case argument
        case named(String)
    }
    
    private struct HintContainer {
        var hints: [String: ParamHint]
    }
    
    enum Error: LocalizedError {
        case missingResolverType
        case nonInitializer
        case expectedArgumentName
        case expectedExpression
        case invalidParamType(String)
        
        var errorDescription: String? {
            switch self {
            case .missingResolverType:
                return "@Resolveable requires a generic parameter"
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

// MARK: - Swift Syntax Extensions

private extension StringLiteralExprSyntax {
    
    var textContent: String? {
        segments.first?.as(StringSegmentSyntax.self)?.content
            .description.trimmingCharacters(in: .init(charactersIn: "\""))
    }
}
