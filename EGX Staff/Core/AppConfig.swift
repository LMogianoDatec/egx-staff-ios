import Foundation

/// Configuración inyectada desde los .xcconfig (Config/) vía Info.plist.
/// `API_BASE_URL` (xcconfig) → `APIBaseURL` (Info.plist) → aquí.
enum AppConfig {
    static var apiBaseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            !raw.isEmpty,
            let url = URL(string: raw)
        else {
            fatalError("APIBaseURL ausente o inválido en Info.plist — revisar Config/*.xcconfig")
        }
        return url
    }
}
