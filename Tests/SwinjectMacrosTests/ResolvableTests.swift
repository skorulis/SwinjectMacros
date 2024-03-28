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
            init(arg1: String, arg2: Int) {
              
            }
            """,
            expandedSource: """
            
            init(arg1: String, arg2: Int) {
              
            }

            static func make(resolver: Resolver) -> Self {
                 return .init(

                 )
            }
            """,
            macros: testMacros
        )
    }
}
