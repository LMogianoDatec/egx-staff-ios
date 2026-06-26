import SwiftUI

struct EventSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Buscar evento"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.egxTextSecondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundStyle(Color.egxText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    Haptics.light()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.egxTextTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .systemGray5).opacity(0.6))
        )
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
    }
}
