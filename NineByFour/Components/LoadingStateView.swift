import SwiftUI

struct LoadingStateView: View {
    var body: some View {
        ZStack {
            Color.Theme.bgBase.ignoresSafeArea()
            ProgressView()
                .tint(Color.Theme.accent)
                .scaleEffect(1.2)
        }
    }
}
