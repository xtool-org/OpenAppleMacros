import SwiftData

@Model
final class QualifiedTransient {
    @SwiftData.Transient var cache: Int = 0
    @Transient var genericCache: Optional<String>
    var name: String = ""

    init() {
        genericCache = nil
    }
}
