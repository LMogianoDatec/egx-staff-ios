import SwiftUI
import UIKit

// Wraps UITextField para poder togglear isSecureTextEntry in-place.
// SwiftUI's if/else entre SecureField y TextField destruye y recrea el campo,
// lo que iOS interpreta como submit del form y dispara el prompt de guardar contraseña.
struct SecureToggleField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var textContentType: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .done
    var onSubmit: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.smartQuotesType = .no
        tf.smartDashesType = .no
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = UIColor(Color.egxText)
        tf.placeholder = placeholder
        tf.textContentType = textContentType
        tf.keyboardType = keyboardType
        tf.returnKeyType = returnKeyType
        tf.isSecureTextEntry = isSecure
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }

        if uiView.isSecureTextEntry != isSecure {
            uiView.isSecureTextEntry = isSecure
            // Forzar redibujado del texto para evitar que quede en blanco al togglear
            if let existing = uiView.text, !existing.isEmpty {
                uiView.text = ""
                uiView.text = existing
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SecureToggleField

        init(_ parent: SecureToggleField) { self.parent = parent }

        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            parent.onSubmit?()
            return true
        }
    }
}
