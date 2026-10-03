import Foundation
import OpenAppleMacrosBase
import SwiftDiagnostics

struct PersistentModelMacro: MemberMacro, MemberAttributeMacro, ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let klass = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: SwiftDataDiagnostic("'@Model' can only be applied to a class")
            ))
            return []
        }
        let name = klass.name.trimmed.text
        let properties = persistedProperties(of: declaration)

        let schemaEntries = properties.map { property in
            let defaultValue = property.initializer ?? "nil"
            let metadata = property.metadata ?? "nil"
            return "    SwiftData.Schema.PropertyMetadata(name: \"\(property.name)\", keypath: \\\(name).\(property.name), defaultValue: \(defaultValue), metadata: \(metadata))"
        }.joined(separator: ",\n")

        let initAssignments = properties.map { property in
            "  _\(property.name) = _SwiftDataNoType()"
        }.joined(separator: "\n")

        return [
            """
            @Transient
            private var _$backingData: any SwiftData.BackingData<\(raw: name)> = \(raw: name).createBackingData()

            public var persistentBackingData: any SwiftData.BackingData<\(raw: name)> {
                get {
                    return _$backingData
                }
                set {
                    _$backingData = newValue
                }
            }
            """,
            """
            class var schemaMetadata: [SwiftData.Schema.PropertyMetadata] {
              return [
            \(raw: schemaEntries)
              ]
            }
            """,
            """
            init(backingData: any SwiftData.BackingData<\(raw: name)>) {
            \(raw: initAssignments)
              self.persistentBackingData = backingData
            }
            """,
            """
            @Transient private let _$observationRegistrar = Observation.ObservationRegistrar()
            """,
            """
            internal nonisolated func access<_M>(
                keyPath: KeyPath<\(raw: name), _M>
            ) {
              _$observationRegistrar.access(self, keyPath: keyPath)
            }
            """,
            """
            internal nonisolated func withMutation<_M, _MR>(
              keyPath: KeyPath<\(raw: name), _M>,
              _ mutation: () throws -> _MR
            ) rethrows -> _MR {
              try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }
            """,
            """
            struct _SwiftDataNoType {
            }
            """,
        ]
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard isPersistedProperty(member) else { return [] }
        return ["@_PersistedProperty"]
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(ClassDeclSyntax.self) else { return [] }
        let name = type.trimmed
        return [
            try ExtensionDeclSyntax("extension \(name): nonisolated SwiftData.PersistentModel {\n}"),
            try ExtensionDeclSyntax("extension \(name): nonisolated Observation.Observable {\n}"),
            try ExtensionDeclSyntax(
                """
                @available(swift, deprecated: 5.9, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(name)'s persistentModelID instead")
                @available(*, unavailable, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(name)'s persistentModelID instead")
                extension \(name): Sendable {
                }
                """
            ),
        ]
    }
}

struct SwiftDataProperty {
    var name: String
    var initializer: String?
    var metadata: String?
    var typeAnnotation: TypeSyntax?
}

func persistedProperties(of declaration: some DeclGroupSyntax) -> [SwiftDataProperty] {
    var properties: [SwiftDataProperty] = []
    for member in declaration.memberBlock.members {
        for property in storedProperties(in: member) where !hasTransientAttribute(property.variable) {
            properties.append(.init(
                name: unbackticked(property.name),
                initializer: property.binding.initializer.map { $0.value.trimmed.description },
                metadata: schemaMetadata(of: property.variable),
                typeAnnotation: property.binding.typeAnnotation?.type.trimmed
            ))
        }
    }
    return properties
}

private struct StoredVariable {
    var variable: VariableDeclSyntax
    var binding: PatternBindingSyntax
    var name: String
}

private func storedProperties(in member: some SyntaxProtocol) -> [StoredVariable] {
    guard let variable = member.as(VariableDeclSyntax.self),
          !variable.modifiers.contains(where: {
              $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
          }) else { return [] }
    return variable.bindings.compactMap { binding in
        guard binding.accessorBlock == nil,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else { return nil }
        return StoredVariable(variable: variable, binding: binding, name: name.text)
    }
}

private func isPersistedProperty(_ member: some SyntaxProtocol) -> Bool {
    guard let variable = member.as(VariableDeclSyntax.self),
          variable.bindingSpecifier.tokenKind == .keyword(.var),
          !variable.modifiers.contains(where: {
              $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
          }),
          !hasTransientAttribute(variable),
          variable.bindings.count == 1,
          let binding = variable.bindings.first,
          binding.accessorBlock == nil,
          binding.pattern.is(IdentifierPatternSyntax.self) else { return false }
    return true
}

private func hasTransientAttribute(_ variable: VariableDeclSyntax) -> Bool {
    variable.attributes.contains(where: { attribute in
        unbackticked(attribute.attributeName.trimmed.description) == "Transient"
    })
}

private func schemaMetadata(of variable: VariableDeclSyntax) -> String? {
    for attribute in variable.attributes {
        guard let attribute = attribute.as(AttributeSyntax.self) else { continue }
        let attributeName = unbackticked(attribute.attributeName.trimmed.description)
        let macroName: String
        switch attributeName {
        case "Attribute", "SwiftData.Attribute":
            macroName = "SwiftData.Schema.Attribute"
        case "Relationship", "SwiftData.Relationship":
            macroName = "SwiftData.Schema.Relationship"
        default:
            continue
        }
        let arguments: String
        if case .argumentList(let list) = attribute.arguments {
            arguments = list.trimmedDescription
        } else {
            arguments = ""
        }
        return "\(macroName)(\(arguments))"
    }
    return nil
}

func unbackticked(_ name: String) -> String {
    guard name.hasPrefix("`"), name.hasSuffix("`"), name.count >= 2 else { return name }
    return String(name.dropFirst().dropLast())
}
