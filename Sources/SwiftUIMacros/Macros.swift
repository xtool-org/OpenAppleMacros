import SwiftSyntax
import SwiftSyntaxMacros
import SwiftCompilerPlugin

@main
struct SwiftUIMacros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EntryMacro.self,
    ]
}

struct EntryMacro: PeerMacro, AccessorMacro {
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let ext = context.lexicalContext.first?.as(ExtensionDeclSyntax.self)

        let kind: EntryKind
        switch ext.map({ "\($0.extendedType.trimmed)" }) {
        case "EnvironmentValues", "SwiftUI.EnvironmentValues", "SwiftUICore.EnvironmentValues":
            kind = .environmentValues
        case "Transaction", "SwiftUI.Transaction", "SwiftUICore.Transaction":
            kind = .transaction
        case "ContainerValues", "SwiftUI.ContainerValues", "SwiftUICore.ContainerValues":
            kind = .containerValues
        case "FocusedValues", "SwiftUI.FocusedValues":
            kind = .focusedValues
        default:
            throw MacroError("'@Entry' can only be applied to 'EnvironmentValues', 'Transaction', 'ContainerValues', or 'FocusedValues'")
        }

        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              varDecl.bindings.count == 1,
              let binding = varDecl.bindings.first,
              let annotation = binding.typeAnnotation,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroError("'@Entry' can only be applied to a 'var' declaration with a simple name")
        }

        guard let initializer = binding.initializer else {
            throw MacroError("'@Entry' requires a default value for the variable")
        }

        return [
            """
            private struct __Key_\(pattern.identifier): \(kind.keyType) {
                static var defaultValue: \(annotation.type) { \(initializer.value) }
            }
            """
        ]
    }

    static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              varDecl.bindings.count == 1,
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw MacroError("'@Entry' can only be applied to a 'var' declaration with a simple name")
        }
        return [
            "get { self[__Key_\(pattern.identifier).self] }",
            "set { self[__Key_\(pattern.identifier).self] = newValue }",
        ]
    }
}

enum EntryKind {
    case environmentValues
    case transaction
    case containerValues
    case focusedValues

    var keyType: TypeSyntax {
        switch self {
        case .environmentValues:
            return "SwiftUICore.EnvironmentKey"
        case .transaction:
            return "SwiftUICore.TransactionKey"
        case .containerValues:
            return "SwiftUICore.ContainerValuesKey"
        case .focusedValues:
            return "SwiftUI.FocusedValuesKey"
        }
    }
}

struct MacroError: Error, CustomStringConvertible {
    let description: String

    init(_ message: String) {
        self.description = message
    }
}
