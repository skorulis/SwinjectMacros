//  Created by Alexander Skorulis on 28/3/2024.

import Foundation
import Swinject
import XCTest
import SwinjectMacros

final class SwinjectResolutionTests: XCTestCase {
    
    func test_simple_service() {
        let container = Factory.basicContainer
        container.register(Service1.self, factory: Service1.make)
        XCTAssertNotNil(container.resolve(Service1.self))
    }
    
    func test_resolve_closure() {
        let container = Factory.basicContainer
        container.register(Service2.self, factory: Service2.make)
        XCTAssertNotNil(container.resolve(Service2.self))
    }
    
}

private struct Service1 {
    
    let string: String
    let value: Int
    
    @Resolvable
    init(string: String, value: Int) {
        self.string = string
        self.value = value
    }
}

private struct Service2 {
    let closure: () -> Void
    
    @Resolvable
    init(closure: @escaping () -> Void) {
        self.closure = closure
    }
}

private enum Factory {
    static var basicContainer: Container {
        let container = Container()
        container.register(String.self) { _ in
            "Test"
        }
        container.register(Int.self) { _ in
            5
        }
        container.register((()->Void).self) { _ in
            return {
                print("Test")
            }
        }
        
        return container
    }
}
