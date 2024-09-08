//  Created by Alexander Skorulis on 28/3/2024.

import SwinjectMacrosImplementations
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwinjectMacrosImplementations)
import SwinjectMacrosImplementations

let testMacros: [String: Macro.Type] = [
    "Resolvable": ResolvableMacro.self
]
#endif

final class ResolvableTests: XCTestCase {
    func test_macro_expansion() throws {
        assertMacroExpansion(
            """
            @Resolvable<Resolver>
            init(arg1: String, arg2: Int) {}
            """,
            expandedSource: """
            
            init(arg1: String, arg2: Int) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     arg1: resolver.string(),
                     arg2: resolver.int()
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_closure_param() throws {
        assertMacroExpansion(
            """
            @Resolvable<CustomResolver>
            init(closure: @escaping () -> Void) {}
            """,
            expandedSource: """
            
            init(closure: @escaping () -> Void) {}

            static func make(resolver: CustomResolver) -> Self {
                 return .init(
                     closure: resolver.closure()
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_default_param() throws {
        assertMacroExpansion(
            """
            @Resolvable<Resolver>
            init(value: Int = 5) {}
            """,
            expandedSource: """
            
            init(value: Int = 5) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     value: 5
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_argument() throws {
        assertMacroExpansion(
            """
            @Resolvable<Resolver>(arguments: ["value"])
            init(value: Int) {}
            """,
            expandedSource: """
            
            init(value: Int) {}

            static func make(resolver: Resolver, value: Int) -> Self {
                 return .init(
                     value: value
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_named() throws {
        assertMacroExpansion(
            """
            @Resolvable<Resolver>(names: ["value": "customName"])
            init(value: Int) {}
            """,
            expandedSource: """
            
            init(value: Int) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     value: resolver.int(name: .customName)
                 )
            }
            """,
            macros: testMacros
        )
    }
}
