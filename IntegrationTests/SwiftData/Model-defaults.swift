import Foundation
import SwiftData

@Model
final class Defaults {
    var name: String = "unnamed"
    var flag: Bool = false
    var rating: Double = 3.5
    var createdAt = Date.now
    var metadata: [String: Int] = [:]
}
