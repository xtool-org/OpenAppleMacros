import OpenAppleMacrosBase

struct PersistedPropertyMacro: PeerMacro, AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let binding = variable.bindings.first,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.unescapedIdentifier else { return [] }
        let type = binding.typeAnnotation?.type
        let optional = type?.is(OptionalTypeSyntax.self) == true ? "?" :
            type?.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) == true ? "!" : ""
        let initial = binding.initializer == nil ? "" : " = _SwiftDataNoType()"
        return ["@Transient\nprivate var _\(raw: name): _SwiftDataNoType\(raw: optional)\(raw: initial)"]
    }

    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.unescapedIdentifier else { return [] }
        let transformable = node.attributeName.trimmed.description == "_TransformablePersistedProperty"
        let setter = transformable ? "setTransformableValue" : "setValue"
        let getter = transformable ? "getTransformableValue" : "getValue"
        var accessors: [AccessorDeclSyntax] = [
            """
            @storageRestrictions(accesses: _$backingData, initializes: _\(raw: name))
            init(initialValue) {
                _$backingData.\(raw: setter)(forKey: \\.\(raw: name), to: initialValue)
                _\(raw: name) = _SwiftDataNoType()
            }
            """,
            """
            get {
                _$observationRegistrar.access(self, keyPath: \\.\(raw: name))
                return self.\(raw: getter)(forKey: \\.\(raw: name))
            }
            """,
        ]
        if variable.bindingSpecifier.tokenKind != .keyword(.let) {
            accessors.append(
            """
            set {
                _$observationRegistrar.withMutation(of: self, keyPath: \\.\(raw: name)) {
                    self.\(raw: setter)(forKey: \\.\(raw: name), to: newValue)
                }
            }
            """)
        }
        return accessors
    }
}

struct TransformablePersistedPropertyMacro: PeerMacro, AccessorMacro {
    static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try PersistedPropertyMacro.expansion(of: node, providingPeersOf: declaration, in: context)
    }

    static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        try PersistedPropertyMacro.expansion(of: node, providingAccessorsOf: declaration, in: context)
    }
}

struct TransientPropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] { [] }
}

struct RelationshipPropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] { [] }
}
