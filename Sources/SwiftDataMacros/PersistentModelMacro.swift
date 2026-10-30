import OpenAppleMacrosBase
import SwiftDiagnostics

struct PersistentModelMacro: MemberMacro, MemberAttributeMacro, ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let cls = declaration.as(ClassDeclSyntax.self)
        let name: String
        if let cls {
            name = cls.name.text
        } else if let value = declaration.as(StructDeclSyntax.self) {
            name = value.name.text
            context.diagnose(Diagnostic(node: node, message: ModelDiagnostic(message: "'@Model' cannot be applied to struct type '\(name)'")))
        } else if let value = declaration.as(EnumDeclSyntax.self) {
            name = value.name.text
            context.diagnose(Diagnostic(node: node, message: ModelDiagnostic(message: "'@Model' cannot be applied to enum type '\(name)'")))
        } else { return [] }
        if !declaration.memberBlock.members.contains(where: { $0.decl.is(InitializerDeclSyntax.self) }) {
            context.diagnose(Diagnostic(node: node, message: ModelDiagnostic(message: "@Model requires an initializer be provided for '\(name)'")))
        }
        let properties = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }.filter(\.isPersisted)
        let metadata = properties.flatMap { variable in
            variable.bindings.prefix(1).compactMap { binding -> String? in
                guard let namePart = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { return nil }
                let initial = binding.initializer?.value.trimmed.description ?? "nil"
                let attribute = variable.attributes.compactMap { $0.as(AttributeSyntax.self) }.first { ["Attribute", "Relationship"].contains($0.attributeName.trimmed.description) }
                let options = attribute?.arguments?.trimmed.description
                let value: String
                if let attribute {
                    let name = attribute.attributeName.trimmed.description
                    value = options.map { "SwiftData.Schema.\(name)(\($0))" } ?? "SwiftData.Schema.\(name) ()"
                } else {
                    value = "nil"
                }
                return "SwiftData.Schema.PropertyMetadata(name: \"\(namePart)\", keypath: \\\(name).\(namePart), defaultValue: \(initial), metadata: \(value))"
            }
        }.joined(separator: ",\n    ")
        let initProperties = properties.compactMap { $0.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }.map { "_\($0) = _SwiftDataNoType()" }.joined(separator: "\n  ")
        let required = cls?.modifiers.contains { $0.name.tokenKind == .keyword(.final) } == true ? "" : "required "
        let access = cls?.modifiers.contains { $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.open) } == true ? "public " : ""
        return [
            "@Transient\nprivate var _$backingData: any SwiftData.BackingData<\(raw: name)> = \(raw: name).createBackingData()",
            """
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
            \(raw: access)class var schemaMetadata: [SwiftData.Schema.PropertyMetadata] {
              return [
                \(raw: metadata)
              ]
            }
            """,
            """
            \(raw: required)\(raw: access)init(backingData: any SwiftData.BackingData<\(raw: name)>) {
              \(raw: initProperties)
              self.persistentBackingData = backingData
            }
            """,
            "@Transient private let _$observationRegistrar = Observation.ObservationRegistrar()",
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
            "struct _SwiftDataNoType {\n}",
        ]
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let variable = member.as(VariableDeclSyntax.self), variable.isPersisted else { return [] }
        if variable.attributes.contains(where: { item in
            guard let attribute = item.as(AttributeSyntax.self), attribute.attributeName.trimmed.description == "Attribute" else { return false }
            guard case .argumentList(let arguments) = attribute.arguments else { return false }
            return arguments.contains { argument in
                guard let call = argument.expression.as(FunctionCallExprSyntax.self),
                      let member = call.calledExpression.as(MemberAccessExprSyntax.self) else { return false }
                return member.declName.baseName.text == "transformable"
            }
        }) {
            return ["@_TransformablePersistedProperty"]
        }
        return ["@_PersistedProperty"]
    }

    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let name = type.trimmed.description
        return [
            try ExtensionDeclSyntax("extension \(raw: name): nonisolated SwiftData.PersistentModel {}"),
            try ExtensionDeclSyntax("extension \(raw: name): nonisolated Observation.Observable {}"),
            try ExtensionDeclSyntax("""
            @available(swift, deprecated: 5.9, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(raw: name)'s persistentModelID instead")
            @available(*, unavailable, message: "PersistentModels are not Sendable, consider utilizing a ModelActor or use \(raw: name)'s persistentModelID instead")
            extension \(raw: name): Sendable {}
            """),
        ]
    }
}

private struct ModelDiagnostic: DiagnosticMessage {
    let message: String
    var diagnosticID: MessageID { MessageID(domain: "SwiftDataMacros", id: message) }
    let severity: DiagnosticSeverity = .error
}

private extension VariableDeclSyntax {
    var isPersisted: Bool {
        guard !modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }),
              !attributes.contains(where: { item in
                  guard let attribute = item.as(AttributeSyntax.self) else { return false }
                  return attribute.attributeName.trimmed.description.split(separator: ".").last == "Transient"
              }) else { return false }
        return bindings.allSatisfy { binding in
            guard let block = binding.accessorBlock else { return true }
            guard case .accessors(let accessors) = block.accessors else { return false }
            return accessors.allSatisfy { $0.accessorSpecifier.tokenKind == .keyword(.willSet) || $0.accessorSpecifier.tokenKind == .keyword(.didSet) }
        }
    }
}
