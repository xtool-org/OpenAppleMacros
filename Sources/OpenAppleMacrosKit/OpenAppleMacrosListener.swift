@_spi(PluginMessage) import SwiftCompilerPluginMessageHandling
import OpenAppleMacrosBase

public struct OpenAppleMacrosListener {
    let connection: StandardIOMessageConnection

    public init(inputFileDescriptor: CInt, outputFileDescriptor: CInt) {
        self.connection = StandardIOMessageConnection(
            inputFileDescriptor: inputFileDescriptor,
            outputFileDescriptor: outputFileDescriptor
        )
    }

    public init() throws {
        self.connection = try StandardIOMessageConnection()
    }

    public func main() throws {
        let listener = CompilerPluginMessageListener(
            connection: connection,
            messageHandler: PluginProviderMessageHandler(provider: Provider())
        )
        try listener.main()
    }

    public static func main() throws {
        try OpenAppleMacrosListener().main()
    }

    public static var moduleNames: [String] {
        allModules
    }
}

private struct Provider: PluginProvider {
    private let macrosByName: [String: Macro.Type]
    private let modules: Set<String>

    init() {
        let macros = allMacros.flatMap { $0 }
        macrosByName = Dictionary(macros.map { (String(reflecting: $0), $0) }) { $1 }
        modules = Set(macrosByName.keys.compactMap { $0.split(separator: ".", maxSplits: 1).first }.map { String($0) })
    }

    var features: [PluginFeature] {
        [.loadPluginLibrary]
    }

    func loadPluginLibrary(libraryPath: String, moduleName: String) throws {
        guard modules.contains(moduleName) else {
            throw MacroError("OpenAppleMacros: Could not find macros for module '\(moduleName)'")
        }
    }

    func resolveMacro(moduleName: String, typeName: String) throws -> Macro.Type {
        let key = "\(moduleName).\(typeName)"
        guard let macro = macrosByName[key] else {
            throw MacroError("OpenAppleMacros: Could not find macro '\(typeName)' in module '\(moduleName)'")
        }
        return macro
    }
}
