import OpenAppleMacrosBase

package var all: [Macro.Type] {
    [
        PersistentModelMacro.self,
        PersistedPropertyMacro.self,
        AttributePropertyMacro.self,
        RelationshipPropertyMacro.self,
        TransientPropertyMacro.self,
        UniqueConstraintsMacro.self,
        IndexMacro.self,
        PersistentModelActorMacro.self,
        QueryMacro.self,
        TransformablePersistedPropertyMacro.self,
    ]
}
