import Foundation
import SwiftData

@Model
final class TransformableExample {
    @Attribute(.transformable(by: "example")) var value: String
    init(value: String) { self.value = value }
}
