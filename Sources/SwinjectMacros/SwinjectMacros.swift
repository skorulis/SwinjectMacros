// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: arbitrary)
public macro Resolvable() = #externalMacro(module: "SwinjectMacrosMacros", type: "ResolvableMacro")
