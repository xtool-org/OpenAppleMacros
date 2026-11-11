import OpenAppleMacrosBase
import SwiftDiagnostics

struct PersistedPropertyMacro: AccessorMacro, PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        return accessors(of: declaration, transformable: false)
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return peer(of: declaration)
    }
}

struct TransformablePersistedPropertyMacro: AccessorMacro, PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        return accessors(of: declaration, transformable: true)
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return peer(of: declaration)
    }
}

private struct PersistedVariable {
    var name: String
    var binding: PatternBindingSyntax
    var isVar: Bool
}

private func persistedVariable(_ declaration: some DeclSyntaxProtocol) -> PersistedVariable? {
    guard let variable = declaration.as(VariableDeclSyntax.self),
          let binding = variable.bindings.first,
          binding.accessorBlock == nil || hasObserversOnly(binding.accessorBlock!),
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
        return nil
    }
    return PersistedVariable(
        name: identifier.trimmed.text,
        binding: binding,
        isVar: variable.bindingSpecifier.tokenKind == .keyword(.var)
    )
}

private func accessors(of declaration: some DeclSyntaxProtocol, transformable: Bool) -> [AccessorDeclSyntax] {
    guard let property = persistedVariable(declaration) else { return [] }
    let name = property.name
    let keyName = unbackticked(name)
    let backing = backingName(name)
    let read = transformable ? "getTransformableValue" : "getValue"
    let write = transformable ? "setTransformableValue" : "setValue"
    var accessors: [AccessorDeclSyntax] = [
        """
        @storageRestrictions(accesses: _$backingData, initializes: \(raw: backing))
        init(initialValue) {
            _$backingData.\(raw: write)(forKey: \\.\(raw: keyName), to: initialValue)
            \(raw: backing) = _SwiftDataNoType()
        }
        """,
        """
        get {
            _$observationRegistrar.access(self, keyPath: \\.\(raw: keyName))
            return self.\(raw: read)(forKey: \\.\(raw: keyName))
        }
        """
    ]
    if property.isVar {
        accessors.append(
            """
            set {
                _$observationRegistrar.withMutation(of: self, keyPath: \\.\(raw: keyName)) {
                    self.\(raw: write)(forKey: \\.\(raw: keyName), to: newValue)
                }
            }
            """
        )
    }
    return accessors
}

private func peer(of declaration: some DeclSyntaxProtocol) -> [DeclSyntax] {
    guard let property = persistedVariable(declaration) else { return [] }
    let name = property.name
    let type = property.binding.typeAnnotation?.type.trimmed
    let optionalSuffix: String
    if type?.as(OptionalTypeSyntax.self) != nil {
        optionalSuffix = "?"
    } else if type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) != nil {
        optionalSuffix = "!"
    } else {
        optionalSuffix = ""
    }
    let initializer = property.binding.initializer != nil ? " = _SwiftDataNoType()" : ""
    return [
        "@Transient\nprivate var \(raw: backingName(name)): _SwiftDataNoType\(raw: optionalSuffix)\(raw: initializer)"
    ]
}

struct AttributePropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct RelationshipPropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct TransientPropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
