import SwiftUI
import SwiftData

@Model
final class Note {
    var text: String = ""
}

struct NotesView: View {
    @Query private var notes: [Note]

    var body: some View {
        Text("hi")
    }
}
