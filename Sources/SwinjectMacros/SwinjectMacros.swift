// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(peer, names: named(make))
public macro Resolvable<ResolverType>(arguments: [String] = [], names: [String: String] = [:]) = #externalMacro(module: "SwinjectMacrosImplementations", type: "ResolvableMacro")
