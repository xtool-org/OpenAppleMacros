import SwiftUI

struct PrivateStateView: View {
    @State private var count: Int = 0

    var body: some View {
        Text("\(count)")
    }
}
