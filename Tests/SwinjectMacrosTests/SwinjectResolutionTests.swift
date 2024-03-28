//  Created by Alexander Skorulis on 28/3/2024.

import Foundation
import Swinject
import XCTest
import SwinjectMacros

final class SwinjectResolutionTests: XCTestCase {
    
    func test_simple_service() {
        let container = Factory.container
        container.register(Service1.self, factory: Service1.make)
        XCTAssertNotNil(container.resolve(Service1.self))
    }
    
    func test_resolve_closure() {
        let container = Factory.container
        container.register(Service2.self, factory: Service2.make)
        XCTAssertNotNil(container.resolve(Service2.self))
    }
    
    func test_default_value() {
        let emptyContainer = Container()
        emptyContainer.register(Service3.self, factory: Service3.make)
        let defaultedService = emptyContainer.resolve(Service3.self)
        XCTAssertEqual(defaultedService?.value, 2)
        
        let filledRouter = Factory.container
        filledRouter.register(Service3.self, factory: Service3.make)
        let service = filledRouter.resolve(Service3.self)
        XCTAssertEqual(service?.value, 5)
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

private struct Service3 {
    
    let value: Int
    
    @Resolvable
    init(defaultedValue: Int = 2) {
        self.value = defaultedValue
    }
}

private enum Factory {
    static var container: Container {
        let container = Container()
        container.register(String.self) { _ in "Test" }
        container.register(Int.self) { _ in 5 }
        container.register((()->Void).self) { _ in
            return {
                print("Test")
            }
        }
        
        return container
    }
}
