import OpenAppleMacrosBase

// Stub macros to allow #Preview to compile.
// We don't actually support viewing previews through xtool.
//
// The SDK declares one `#Preview` overload per kind of preview, each backed by
// a different macro type in `PreviewsMacros`:
//
// | Type                 | Used by                                           |
// | -------------------- | ------------------------------------------------- |
// | `SwiftUIView`        | SwiftUI `#Preview { ... }`                        |
// | `SwiftUIViewGroup_1` | SwiftUI `#Preview(arguments:)`                    |
// | `KitViewMacro`       | UIKit/AppKit views and view controllers           |
// | `PreviewCommonGroup` | UIKit/AppKit `#Preview(arguments:)`               |
// | `Common`             | WidgetKit (widgets, timelines, Live Activities)   |

package var all: [Macro.Type] {
    [
        SwiftUIView.self,
        SwiftUIViewGroup_1.self,
        KitViewMacro.self,
        PreviewCommonGroup.self,
        Common.self,
        Previewable.self,
    ]
}

struct SwiftUIView: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct SwiftUIViewGroup_1: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct KitViewMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct PreviewCommonGroup: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

struct Common: DeclarationMacro {
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
