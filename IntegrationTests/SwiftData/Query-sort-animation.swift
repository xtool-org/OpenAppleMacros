import SwiftUI
import SwiftData

@Model
final class Note {
    var text: String = ""
    var date: Date = Date.now
}

struct SortedView: View {
    @Query(sort: \Note.date, order: .reverse, animation: .default) private var notes: [Note]

    var body: some View {
        Text("hi")
    }
}
