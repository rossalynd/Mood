
import SwiftUI
@available(iOS 26.0, *)
struct ProfileView: View {
    @Binding var path: NavigationPath
    var body: some View {
        ZStack {
            LiquidBackdrop().ignoresSafeArea()
            Text("Profile Placeholder")
                .font(.title2.weight(.semibold))
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Profile").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(.thinMaterial)
            .overlay(alignment: .bottom) { Divider().opacity(0.25) }
        }
    }
}
