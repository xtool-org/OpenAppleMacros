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
        // Enumerations are ignored entirely.
        if declaration.is(EnumDeclSyntax.self) {
            return []
        }

        let name = typeName(of: declaration)
        let misuseKind: String?
        if let klass = declaration.as(ClassDeclSyntax.self) {
            misuseKind = klass.classKeyword.tokenKind == .keyword(.actor) ? "actor" : nil
        } else if declaration.is(StructDeclSyntax.self) {
            misuseKind = "struct"
        } else {
            misuseKind = nil
        }
        if let misuseKind {
            context.diagnose(Diagnostic(
                node: node,
                message: SwiftDataDiagnostic("'@Model' cannot be applied to \(misuseKind) type '\(name)'")
            ))
        }
        if !hasExplicitInitializer(declaration) {
            context.diagnose(Diagnostic(
                node: node,
                message: SwiftDataDiagnostic("@Model requires an initializer be provided for '\(name)'")
            ))
        }

        let isFinalClass = declaration.is(ClassDeclSyntax.self)
            && declaration.modifiers.contains { $0.name.tokenKind == .keyword(.final) }
        let requiredPrefix = isFinalClass ? "" : "required "
        let publicPrefix = declaration.modifiers.contains { $0.name.tokenKind == .keyword(.public) } ? "public " : ""

        diagnoseTransientDefaults(declaration, in: context)

        let properties = persistedProperties(of: declaration)
        let extraMetadata = extraSchemaProperties(of: declaration)

        var schemaBody: String
        if extraMetadata.isEmpty {
            let schemaEntries = properties.map { property in
                "    SwiftData.Schema.PropertyMetadata(name: \"\(property.name)\", keypath: \\\(name).\(property.name), defaultValue: \(property.initializer ?? "nil"), metadata: \(property.metadata ?? "nil"))"
            }.joined(separator: ",\n")
            schemaBody = "  return [\n\(schemaEntries)\n  ]"
        } else {
            let schemaEntries = properties.map { property in
                "    SwiftData.Schema.PropertyMetadata(name: \"\(property.name)\", keypath: \\\(name).\(property.name), defaultValue: \(property.initializer ?? "nil"), metadata: \(property.metadata ?? "nil"))"
            }.joined(separator: ",\n")
            schemaBody = """
              let storedProperties = [
            \(raw: schemaEntries)
              ]
              var otherProperties = [SwiftData.Schema.PropertyMetadata]()
            \(raw: extraMetadata.joined(separator: "\n"))
              return storedProperties + otherProperties
            """
        }

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
            \(raw: publicPrefix)class var schemaMetadata: [SwiftData.Schema.PropertyMetadata] {
            \(raw: schemaBody)
            }
            """,
            """
            \(raw: requiredPrefix)\(raw: publicPrefix)init(backingData: any SwiftData.BackingData<\(raw: name)>) {
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
}

func typeName(of declaration: some DeclGroupSyntax) -> String {
    if let named = declaration.asProtocol(NamedDeclSyntax.self) {
        return named.name.trimmed.text
    }
    return "_"
}

private func hasExplicitInitializer(_ declaration: some DeclGroupSyntax) -> Bool {
    declaration.memberBlock.members.contains { member in
        member.decl.is(InitializerDeclSyntax.self)
    }
}

private func diagnoseTransientDefaults(
    _ declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
) {
    for member in declaration.memberBlock.members {
        guard let variable = member.decl.as(VariableDeclSyntax.self),
              variable.bindingSpecifier.tokenKind == .keyword(.var),
              !variable.modifiers.contains(where: {
                  $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
              }),
              let transientAttribute = variable.attributes.compactMap({ $0.as(AttributeSyntax.self) }).first(where: {
                  unbackticked($0.attributeName.trimmed.description) == "Transient"
              }) else { continue }
        for binding in variable.bindings {
            guard binding.accessorBlock == nil,
                  binding.initializer == nil,
                  let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else { continue }
            let type = binding.typeAnnotation?.type.trimmed
            let isOptional = type?.as(OptionalTypeSyntax.self) != nil
                || type?.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) != nil
            if !isOptional {
                context.diagnose(Diagnostic(
                    node: transientAttribute,
                    message: SwiftDataDiagnostic("@Transient requires non-optional property '\(name.trimmed.text)' to have a default value")
                ))
            }
        }
    }
}

/// Emits the `#Unique`/`#Index` entries for the `otherProperties` section, if any.
private func extraSchemaProperties(of declaration: some DeclGroupSyntax) -> [String] {
    var entries: [String] = []
    for member in declaration.memberBlock.members {
        guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self) else { continue }
        let macroName = unbackticked(expansion.macro.trimmed.description)
        let kind: String
        switch macroName {
        case "Unique", "SwiftData.Unique":
            kind = "Unique"
        case "Index", "SwiftData.Index":
            kind = "Index"
        default:
            continue
        }
        let genericArguments = expansion.genericArgumentClause.map { "\($0.trimmed)" } ?? ""
        let arguments = expansion.arguments.trimmedDescription
        let metadata = "SwiftData.Schema.\(kind)\(genericArguments)(\(arguments))"
        entries.append(
            """
              if #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) {
                otherProperties.append(
                  SwiftData.Schema.PropertyMetadata(name: "SwiftData.Schema.\(kind)", keypath: \\SwiftData.Schema.encodingVersion, defaultValue: nil, metadata: \(metadata)))
              }
            """
        )
    }
    return entries
}

func persistedProperties(of declaration: some DeclGroupSyntax) -> [SwiftDataProperty] {
    var properties: [SwiftDataProperty] = []
    for member in declaration.memberBlock.members {
        for property in storedVariables(in: member) where !hasTransientAttribute(property.variable) {
            properties.append(.init(
                name: unbackticked(property.name),
                initializer: property.binding.initializer.map { $0.value.trimmed.description },
                metadata: schemaMetadata(of: property.variable)
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

private func storedVariables(in member: MemberBlockItemSyntax) -> [StoredVariable] {
    guard let variable = member.decl.as(VariableDeclSyntax.self),
          !variable.modifiers.contains(where: {
              $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
          }) else { return [] }
    return variable.bindings.compactMap { binding in
        guard binding.accessorBlock == nil,
              let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else { return nil }
        return StoredVariable(variable: variable, binding: binding, name: name.text)
    }
}

func isPersistedProperty(_ member: some SyntaxProtocol) -> Bool {
    guard let variable = member.as(VariableDeclSyntax.self),
          !variable.modifiers.contains(where: {
              $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
          }),
          !hasTransientAttribute(variable),
          !variable.bindings.isEmpty,
          variable.bindings.allSatisfy({ binding in
              binding.accessorBlock == nil && binding.pattern.is(IdentifierPatternSyntax.self)
          }) else { return false }
    return true
}

private func hasTransientAttribute(_ variable: VariableDeclSyntax) -> Bool {
    variable.attributes.contains(where: { attribute in
        guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
        return unbackticked(attribute.attributeName.trimmed.description) == "Transient"
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
