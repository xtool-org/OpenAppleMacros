import SwiftData

struct Value {
    @Attribute(.unique) var id: String = ""
}

enum E {
    @Attribute var value: Int { 1 }
}
