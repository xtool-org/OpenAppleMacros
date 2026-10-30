import Foundation
import SwiftData

@Model
final class Document {
    @Attribute(.unique) var identifier: String
    @Attribute(originalName: "title") var name: String = ""
    @Attribute(.externalStorage) var contents: Data

    init(identifier: String, contents: Data) {
        self.identifier = identifier
        self.contents = contents
    }
}
