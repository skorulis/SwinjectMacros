// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: named(make))
public macro Resolvable<ResolverType>(arguments: [String] = [], names: [String: String] = [:]) = #externalMacro(module: "SwinjectMacrosImplementations", type: "ResolvableMacro")

@attached(peer)
public macro Argument(_ name: String) = #externalMacro(module: "SwinjectMacrosImplementations", type: "ArgumentMacro")

@attached(peer)
public macro Named(_ variable: String, _ name: String) = #externalMacro(module: "SwinjectMacrosImplementations", type: "NamedMacro")
