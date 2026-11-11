import SwiftData

@Model
final class Attributed {
    @Attribute(.unique) var id: String = ""
    @Attribute(.externalStorage) var blob: Data = Data()
    @Attribute(originalName: "legacy_name") var renamed: String = ""
    @Attribute(.unique, originalName: "old", hashModifier: "h1") var composite: Int = 0
    @Attribute var bare: Int = 0
}
