import SwiftData

@SwiftData.Model
public class Record {
    @SwiftData.Attribute(.unique, originalName: "oldID") public var id: String
    var optional: Int?
    var defaultValue = 42
    var ignored: String { id }

    public init(id: String) {
        self.id = id
    }
}
