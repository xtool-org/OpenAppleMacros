import OpenAppleMacrosBase
import SwiftDiagnostics

struct UniqueConstraintsMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct IndexMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct PersistentModelActorMacro: MemberMacro, ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            """
            nonisolated let modelExecutor: any SwiftData.ModelExecutor
            nonisolated let modelContainer: SwiftData.ModelContainer

            init(modelContainer: SwiftData.ModelContainer) {
                let modelContext = ModelContext(modelContainer)
                self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
                self.modelContainer = modelContainer
            }
            """
        ]
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
            try ExtensionDeclSyntax("extension \(name): SwiftData.ModelActor {\n}")
        ]
    }
}

struct QueryMacro: AccessorMacro, PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let variable = declaration.as(VariableDeclSyntax.self),
              variable.bindings.count == 1,
              let binding = variable.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            return []
        }
        let name = identifier.trimmed.text
        return [
            """
            get {
                _\(raw: name).wrappedValue
            }
            """
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
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
              let type = binding.typeAnnotation?.type.trimmed else {
            return []
        }
        let name = identifier.trimmed.text
        let arguments: String
        if case .argumentList(let list) = node.arguments {
            arguments = list.trimmedDescription
        } else {
            arguments = ""
        }
        return [
            "private(set) var _\(raw: name): SwiftData.Query<\(raw: type).Element, \(raw: type)> = .init(\(raw: arguments))"
        ]
    }
}

struct SwiftDataDiagnostic: DiagnosticMessage, FixItMessage {
    let message: String
    let severity: DiagnosticSeverity

    init(_ message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        self.severity = severity
    }

    var diagnosticID: MessageID {
        MessageID(domain: "SwiftDataMacros", id: message)
    }
    var fixItID: MessageID { diagnosticID }
}
