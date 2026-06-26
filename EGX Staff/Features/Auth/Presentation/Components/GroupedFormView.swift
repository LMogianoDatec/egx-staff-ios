import SwiftUI

struct GroupedFormView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .glassSurface(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

struct FormFieldRow<Trailing: View>: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var isToggleable: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var returnKeyType: UIReturnKeyType = .done
    var onSubmit: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(Color.egxFormLabel)
                .frame(width: 96, alignment: .leading)

            if isToggleable {
                // Siempre UITextField: isSecureTextEntry se cambia in-place sin destruir la vista.
                // Si usáramos if/else entre SecureField y TextField, SwiftUI recrearía el campo
                // y iOS interpretaría eso como submit → prompt de guardar contraseña.
                SecureToggleField(
                    placeholder: placeholder,
                    text: $text,
                    isSecure: isSecure,
                    textContentType: textContentType,
                    keyboardType: keyboardType,
                    returnKeyType: returnKeyType,
                    onSubmit: onSubmit
                )
            } else if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.egxText)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(.none)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.egxText)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()
                    .keyboardType(keyboardType)
            }

            trailing()
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }
}

extension FormFieldRow where Trailing == EmptyView {
    init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        isSecure: Bool = false,
        isToggleable: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .never,
        returnKeyType: UIReturnKeyType = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isSecure = isSecure
        self.isToggleable = isToggleable
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.returnKeyType = returnKeyType
        self.onSubmit = onSubmit
        self.trailing = { EmptyView() }
    }
}

struct FormDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.egxFormDivider)
            .frame(height: 0.5)
            .padding(.leading, 18)
    }
}
