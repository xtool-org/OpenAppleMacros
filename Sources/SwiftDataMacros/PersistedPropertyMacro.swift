import OpenAppleMacrosBase
import SwiftDiagnostics

struct PersistedPropertyMacro: AccessorMacro, PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let name = persistedPropertyName(declaration) else { return [] }
        return [
            """
            @storageRestrictions(accesses: _$backingData, initializes: _\(raw: name))
            init(initialValue) {
                _$backingData.setValue(forKey: \\.\(raw: name), to: initialValue)
                _\(raw: name) = _SwiftDataNoType()
            }
            get {
                _$observationRegistrar.access(self, keyPath: \\.\(raw: name))
                return self.getValue(forKey: \\.\(raw: name))
            }
            set {
                _$observationRegistrar.withMutation(of: self, keyPath: \\.\(raw: name)) {
                    self.setValue(forKey: \\.\(raw: name), to: newValue)
                }
            }
            """,
        ]
    }

    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              variable.bindings.count == 1,
              let binding = variable.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            return []
        }
        let name = identifier.trimmed.text
        let type = binding.typeAnnotation?.type.trimmed
        let optionalSuffix: String
        if type?.as(OptionalTypeSyntax.self) != nil {
            optionalSuffix = "?"
        } else if type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) != nil {
            optionalSuffix = "!"
        } else {
            optionalSuffix = ""
        }
        let initializer = binding.initializer != nil ? " = _SwiftDataNoType()" : ""
        return [
            "@Transient\nprivate var _\(raw: name): _SwiftDataNoType\(raw: optionalSuffix)\(raw: initializer)"
        ]
    }
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

private func persistedPropertyName(_ declaration: some DeclSyntaxProtocol) -> String? {
    guard let variable = declaration.as(VariableDeclSyntax.self),
          variable.bindings.count == 1,
          let binding = variable.bindings.first,
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
        return nil
    }
    return identifier.trimmed.text
}
