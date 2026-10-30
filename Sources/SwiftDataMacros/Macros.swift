import OpenAppleMacrosBase
import SwiftDiagnostics

package var all: [Macro.Type] {
    [AttributePropertyMacro.self, PersistentModelMacro.self, PersistedPropertyMacro.self, TransformablePersistedPropertyMacro.self, TransientPropertyMacro.self, RelationshipPropertyMacro.self]
}

struct AttributePropertyMacro: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let enclosingType = context.lexicalContext.first { $0.asProtocol(DeclGroupSyntax.self) != nil }
        if enclosingType?.is(ClassDeclSyntax.self) != true {
            context.diagnose(Diagnostic(node: node, message: AttributeDiagnostic(message: "@Attribute can only be used within a class")))
        }
        if let variable = declaration.as(VariableDeclSyntax.self), variable.bindings.contains(where: { $0.accessorBlock != nil }) {
            context.diagnose(Diagnostic(node: node, message: AttributeDiagnostic(message: "@Attribute can only be used with a stored property")))
        }
        return []
    }
}

private struct AttributeDiagnostic: DiagnosticMessage {
    let message: String
    var diagnosticID: MessageID { MessageID(domain: "SwiftDataMacros", id: message) }
    let severity: DiagnosticSeverity = .warning
}
