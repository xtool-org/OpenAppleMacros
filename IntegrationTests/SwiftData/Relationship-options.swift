import SwiftData

@Model
final class Parent {
    var name: String = ""
    @Relationship(deleteRule: .cascade) var cascading: [Child] = []
    @Relationship(deleteRule: .nullify) var nullifying: [Child] = []
    @Relationship(deleteRule: .noAction) var untouched: [Child] = []
    @Relationship(deleteRule: .deny) var denied: [Child] = []
    @Relationship(inverse: \Child.parent) var withInverse: [Child] = []
    @Relationship(minimumModelCount: 1, maximumModelCount: 10) var bounded: [Child] = []
    @Relationship(originalName: "old_rel", hashModifier: "h") var renamed: [Child] = []
    @Relationship var plain: [Child] = []
    @Relationship(deleteRule: .nullify) var optionalChild: Child?
}

@Model
final class Child {
    var name: String = ""
    var parent: Parent?
}
