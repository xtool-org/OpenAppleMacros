import SystemPackage
import WASI
import WasmTypes

typealias WasmFunction = () throws -> Void

protocol WasmEngine {
  init(pluginPath: FilePath) throws

  func function(named name: String) throws -> WasmFunction?

  func writeToPlugin(_ storage: some Sequence<UInt8>) throws
  func readFromPlugin(into storage: UnsafeMutableRawBufferPointer) throws -> Int

  func shutDown() throws
}

typealias DefaultWasmPlugin = WasmEnginePlugin<DefaultWasmEngine>

// a WasmPlugin implementation that delegates to a WasmEngine
struct WasmEnginePlugin<Engine: WasmEngine>: WasmPlugin {
  private let pumpFunction: WasmFunction
  let engine: Engine

  init(path: String) throws {
    self.engine = try Engine(pluginPath: FilePath(path))

    let exportName = "swift_wasm_macro_v1_pump"
    guard let pump = try engine.function(named: exportName) else {
      throw WasmEngineError(message: "Wasm plugin has an unknown ABI (could not find '\(exportName)')")
    }
    self.pumpFunction = pump

    guard let start = try engine.function(named: "_start") else {
      throw WasmEngineError(message: "Wasm plugin does not have a '_start' entrypoint")
    }
    try start()
  }

  func handleMessage(_ json: [UInt8]) throws -> [UInt8] {
    try withUnsafeBytes(of: UInt64(json.count).littleEndian) {
      _ = try engine.writeToPlugin($0)
    }
    try engine.writeToPlugin(json)

    try self.pumpFunction()

    let lengthRaw = try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 8) { buffer in
      let lengthCount = try engine.readFromPlugin(into: UnsafeMutableRawBufferPointer(buffer))
      guard lengthCount == 8 else {
        throw WasmEngineError(message: "Wasm plugin sent invalid response")
      }
      return buffer.withMemoryRebound(to: UInt64.self, \.baseAddress!.pointee)
    }
    let length = Int(UInt64(littleEndian: lengthRaw))
    return try [UInt8](unsafeUninitializedCapacity: length) { buffer, size in
      let received = try engine.readFromPlugin(into: UnsafeMutableRawBufferPointer(buffer))
      guard received == length else {
        throw WasmEngineError(message: "Wasm plugin sent truncated response")
      }
      size = received
    }
  }

  func shutDown() throws {
    try self.engine.shutDown()
  }
}

struct WasmEngineError: Error, CustomStringConvertible {
  let description: String

  init(message: String) {
    self.description = message
  }
}
