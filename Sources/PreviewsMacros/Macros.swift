import OpenAppleMacrosBase

// Stub macros to allow #Preview to compile.
// We don't actually support viewing previews through xtool.

package let all: [Macro.Type] = [
    SwiftUIView.self,
    Previewable.self,
]

struct SwiftUIView: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax, 
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct Previewable: PeerMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
