import SwiftData

@Model
final class Constrained {
    var email: String = ""
    var handle: String = ""

    #Unique<Constrained>([\.email], [\.handle])
}
