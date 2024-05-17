// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: named(make))
public macro Resolvable() = #externalMacro(module: "SwinjectMacrosImplementations", type: "ResolvableMacro")

@attached(peer)
public macro Argument(_ name: String) = #externalMacro(module: "SwinjectMacrosImplementations", type: "ArgumentMacro")
