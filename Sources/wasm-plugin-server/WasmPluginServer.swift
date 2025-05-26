@_spi(PluginMessage) import SwiftCompilerPluginMessageHandling

@main
enum SwiftPluginServer {
  static func main() throws {
    let connection = try StandardIOMessageConnection()
    let listener = CompilerPluginMessageListener(
      connection: connection,
      messageHandler: WasmMessageHandler()
    )
    listener.main()
  }
}
