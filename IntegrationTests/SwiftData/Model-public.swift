import SwiftData

@Model
public class PublicModel {
    public var name: String = ""
    var internal_: Int = 0
    private var secret: String = ""

    public init() {}
}
