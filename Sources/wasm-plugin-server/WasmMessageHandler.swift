@_spi(PluginMessage) import SwiftCompilerPluginMessageHandling

/// A `PluginMessageHandler` that handles Wasm plugins.
final class WasmMessageHandler: PluginMessageHandler {
  private var loadedWasmPlugins: [String: any WasmPlugin] = [:]

  init() {}

  func handleMessage(_ message: HostToPluginMessage) -> PluginToHostMessage {
    switch message {
    case let .loadPluginLibrary(libraryPath, moduleName):
      do {
        self.loadedWasmPlugins[moduleName] = try DefaultWasmPlugin(path: libraryPath)
      } catch {
        return .loadPluginLibraryResult(
          loaded: false,
          diagnostics: [PluginMessage.Diagnostic(errorMessage: "\(error)")]
        )
      }
      return .loadPluginLibraryResult(loaded: true, diagnostics: [])
    case let .expandAttachedMacro(macro, _, _, syntax, _, _, _, _, _),
         let .expandFreestandingMacro(macro, _, _, syntax, _):
      return self.expandMacro(macro, message: message, location: syntax.location)
    case .getCapability:
      let capability = PluginMessage.PluginCapability(
        protocolVersion: PluginMessage.PROTOCOL_VERSION_NUMBER,
        features: [PluginFeature.loadPluginLibrary.rawValue]
      )
      return .getCapabilityResult(capability: capability)
    }
  }

  func shutDown() throws {
    for plugin in self.loadedWasmPlugins.values {
      try plugin.shutDown()
    }

    self.loadedWasmPlugins = [:]
  }

  private func expandMacro(
    _ macro: PluginMessage.MacroReference,
    message: HostToPluginMessage,
    location: PluginMessage.SourceLocation?
  ) -> PluginToHostMessage {
    guard let plugin = self.loadedWasmPlugins[macro.moduleName] else { 
      return .expandMacroResult(
        expandedSource: nil,
        diagnostics: [PluginMessage.Diagnostic(
          errorMessage: """
          failed to communicate with external macro implementation type \
          '\(macro.moduleName).\(macro.typeName)' to expand macro '\(macro.name)'; \
          could not find plugin for module '\(macro.moduleName)'
          """,
          position: location?.position ?? .invalid
        )]
      )
    }
    do {
      let request = try JSON.encode(message)
      let responseRaw = try plugin.handleMessage(request)
      return try responseRaw.withUnsafeBytes {
        try $0.withMemoryRebound(to: UInt8.self) {
          try JSON.decode(PluginToHostMessage.self, from: $0)
        }
      }
    } catch {
      return .expandMacroResult(
        expandedSource: nil,
        diagnostics: [PluginMessage.Diagnostic(
          errorMessage: """
          failed to communicate with external macro implementation type \
          '\(macro.moduleName).\(macro.typeName)' to expand macro '\(macro.name)'; \
          \(error)
          """,
          position: location?.position ?? .invalid
        )]
      )
    }
  }
}

fileprivate extension PluginMessage.Diagnostic {
  init(
    errorMessage: String,
    position: PluginMessage.Diagnostic.Position = .invalid
  ) {
    self.init(
      message: errorMessage,
      severity: .error,
      position: position,
      highlights: [],
      notes: [],
      fixIts: []
    )
  }
}

fileprivate extension PluginMessage.SourceLocation {
  var position: PluginMessage.Diagnostic.Position {
    .init(fileName: fileName, offset: offset)
  }
}

protocol WasmPlugin {
  init(path: String) throws

  func handleMessage(_ json: [UInt8]) throws -> [UInt8]

  func shutDown() throws
}
