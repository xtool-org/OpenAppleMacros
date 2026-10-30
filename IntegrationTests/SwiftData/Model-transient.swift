import SwiftData

@Model
final class Cache {
    var name: String
    @Transient var temporary: Int = 0

    init(name: String) {
        self.name = name
    }
}
