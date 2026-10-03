import SwiftData

@Model
final class Mixed {
    var email: String = ""
    var city: String = ""

    #Unique<Mixed>([\.email])
    #Index<Mixed>([\.city])
}
