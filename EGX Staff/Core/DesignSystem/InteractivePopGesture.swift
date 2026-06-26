import SwiftUI
import UIKit

/// Re-habilita el gesto nativo de "deslizar para volver" cuando la barra de
/// navegación está oculta (`toolbar(.hidden, for: .navigationBar)` normalmente
/// lo desactiva). Scoped: aplicar solo en las pantallas que lo necesiten.
extension View {
    func enableInteractivePopGesture() -> some View {
        background(InteractivePopGestureEnabler().frame(width: 0, height: 0))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Enabler {
        let vc = Enabler()
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: Enabler, context: Context) {
        uiViewController.coordinator = context.coordinator
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let nav = (gestureRecognizer.view?.next as? UINavigationController)
                         ?? gestureRecognizer.view?.findNavigationController()
            else { return true }
            let should = nav.viewControllers.count > 1
            return should
        }
    }
}

// UIViewController subclass: usa viewWillAppear en lugar de updateUIViewController
// para evitar race entre múltiples enablers en el stack. UIKit garantiza el orden;
// DispatchQueue.main.async no lo hace.
private final class Enabler: UIViewController {
    weak var coordinator: InteractivePopGestureEnabler.Coordinator?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController else { return }
        nav.interactivePopGestureRecognizer?.isEnabled = true
        nav.interactivePopGestureRecognizer?.delegate = coordinator
    }
}

private extension UIView {
    func findNavigationController() -> UINavigationController? {
        sequence(first: self.next, next: { $0?.next })
            .compactMap { $0 as? UINavigationController }
            .first
    }
}
