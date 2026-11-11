import SwiftData

@Model
final class Indexed {
    var name: String = ""
    var age: Int = 0

    #Index<Indexed>([\.name], [\.name, \.age])
}
