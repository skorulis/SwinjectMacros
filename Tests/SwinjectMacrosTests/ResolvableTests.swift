//  Created by Alexander Skorulis on 28/3/2024.

import SwinjectMacrosImplementations
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwinjectMacrosImplementations)
import SwinjectMacrosImplementations

let testMacros: [String: Macro.Type] = [
    "Resolvable": ResolvableMacro.self,
    "Argument": ArgumentMacro.self,
]
#endif

final class ResolvableTests: XCTestCase {
    func test_macro_expansion() throws {
        assertMacroExpansion(
            """
            @Resolvable
            init(arg1: String, arg2: Int) {}
            """,
            expandedSource: """
            
            init(arg1: String, arg2: Int) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     arg1: resolver.resolve(String.self)!,
                     arg2: resolver.resolve(Int.self)!
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_closure_param() throws {
        assertMacroExpansion(
            """
            @Resolvable
            init(closure: @escaping () -> Void) {}
            """,
            expandedSource: """
            
            init(closure: @escaping () -> Void) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     closure: resolver.resolve((() -> Void).self)!
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_default_param() throws {
        assertMacroExpansion(
            """
            @Resolvable
            init(value: Int = 5) {}
            """,
            expandedSource: """
            
            init(value: Int = 5) {}

            static func make(resolver: Resolver) -> Self {
                 return .init(
                     value: resolver.resolve(Int.self) ?? 5
                 )
            }
            """,
            macros: testMacros
        )
    }
    
    func test_argument() throws {
        assertMacroExpansion(
            """
            @Resolvable
            @Argument("value")
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
}
