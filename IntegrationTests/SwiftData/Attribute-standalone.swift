import SwiftData

class Item {
    @Attribute(.unique) var name: String = ""
    @Attribute(originalName: "oldValue") var value: Int = 0
}

struct InvalidItem {
    @Attribute(.unique) var name: String = ""
}
