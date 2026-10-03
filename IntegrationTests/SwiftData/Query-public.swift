import SwiftUI
import SwiftData

@Model
final class Entry {
    var title: String = ""
}

struct EntryView: View {
    @Query(sort: \Entry.title) var entries: [Entry]

    var body: some View {
        Text("hi")
    }
}
