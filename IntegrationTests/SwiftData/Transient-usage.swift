import SwiftData

@Model
final class WithTransient {
    var name: String = ""
    @Transient var cache: Int = 0
    @Transient var cacheNoDefault: Int
    @Transient var weakref: String?

    init() {
        cacheNoDefault = 0
    }
}
