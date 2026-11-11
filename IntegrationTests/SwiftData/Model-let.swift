import SwiftData

@Model
final class WithLet {
    let identity: String
    var name: String = ""

    init(identity: String) {
        self.identity = identity
    }
}
