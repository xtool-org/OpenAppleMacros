import SwiftData

enum Namespace {
    @Model
    final class Item {
        var values: [String] = []
        var flag = false
        var text: String? = nil
        init() {}
    }
}
