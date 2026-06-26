import SwiftUI

struct LogoView: View {
    var size: CGFloat = 64

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)

        Image("GeniousNeutral")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(size * 0.12)
            .frame(width: size, height: size)
            .glassSurface(in: shape, tint: .white)
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    VStack(spacing: 24) {
        LogoView(size: 64)
        LogoView(size: 80)
        LogoView(size: 96)
    }
    .padding()
    .background(Color.egxBackground)
}
