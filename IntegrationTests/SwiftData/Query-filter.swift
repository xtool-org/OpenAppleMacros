import SwiftUI
import SwiftData

@Model
final class Task {
    var done: Bool = false
}

struct TaskView: View {
    @Query(filter: #Predicate<Task> { !$0.done }, sort: \Task.done) private var tasks: [Task]

    var body: some View {
        Text("hi")
    }
}
