import Foundation

/// Punto de entrada único para registrar todas las dependencias.
/// Equivalente a `setupLocator()` en Flutter/GetIt.
enum Injection {
    static func setup(apiConfiguration: APIConfiguration = .development) {
        // Core
        CoreModule.register(apiConfiguration: apiConfiguration)

        // Features
        AuthModule.register()
        EventsModule.register()
        ScannerModule.register()
    }

    /// Limpia todas las registraciones — útil para tests.
    static func reset() {
        sl.reset()
    }
}
