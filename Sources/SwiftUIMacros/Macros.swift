import OpenAppleMacrosBase

package var all: [Macro.Type] {
    [
        EntryMacro.self,
        EntryDefaultValueMacro.self,
        StateMacro.self,
        ProjectedValueMacro.self,
        StateProjectedValueMacro.self,
        StatePropertyWrapperStorageMacro.self,
        StateInitialStoredValueMacro.self,
    ]
}
