import SwiftUI
import SwiftData

@Model
final class EscapedNote {
    var text: String = ""
}

struct EscapedQueryView: View {
    @Query private var `default`: [EscapedNote]

    var body: some View {
        Text("hi")
    }
}
