import SwiftData

@Model
final class WithTransformable {
    @_TransformablePersistedProperty var payload: Data = Data()
}
