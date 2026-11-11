import SwiftUI
import SwiftData

@Model
final class Item {
    var name: String = ""
}

struct ItemView: View {
    @Query(FetchDescriptor<Item>()) private var items: [Item]

    var body: some View {
        Text("hi")
    }
}
