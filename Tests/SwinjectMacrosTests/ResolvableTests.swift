//  Created by Alexander Skorulis on 28/3/2024.

import SwinjectMacrosMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(SwinjectMacrosMacros)
import SwinjectMacrosMacros

let testMacros: [String: Macro.Type] = [
    "Resolvable": ResolvableMacro.self
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
}
