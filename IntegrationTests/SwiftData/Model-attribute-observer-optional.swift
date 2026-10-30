import SwiftData

@Model final class Edge {
    @Attribute(.unique) var id: String { didSet {} }
    var longOptional: Optional<String>
    var implicit: String!
    init(id: String) { self.id = id }
}
