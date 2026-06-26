import SwiftUI
import UIKit

enum CachedImagePhase {
    case empty
    case success(Image)
    case failure

    /// `true` mientras aún se descarga (sin resolver): controla el skeleton.
    var isLoading: Bool {
        if case .empty = self { return true }
        return false
    }
}

/// Carga imágenes remotas con caché de dos niveles, indexado por la URL:
/// - memoria: `NSCache` de `UIImage` decodificadas (key = `url.absoluteString`).
/// - disco: `URLCache` dedicado, sobrevive reinicios de la app.
final class ImageLoaderCache: @unchecked Sendable {
    static let shared = ImageLoaderCache()

    private let memory = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        let disk = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "egx.images"
        )
        let config = URLSessionConfiguration.default
        config.urlCache = disk
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        memory.countLimit = 250
    }

    /// Hit síncrono en memoria — usar para evitar parpadeo al reusar celdas.
    func cachedImage(forKey key: String) -> UIImage? {
        memory.object(forKey: key as NSString)
    }

    func image(for url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        if let cached = memory.object(forKey: key) { return cached }

        do {
            let (data, _) = try await session.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            // Decodifica el bitmap fuera del main thread: al setear `.success`
            // la imagen se dibuja sin hitch y el skeleton desaparece al instante.
            let decoded = await image.byPreparingForDisplay() ?? image
            memory.setObject(decoded, forKey: key)
            return decoded
        } catch {
            return nil
        }
    }
}

/// Reemplazo de `AsyncImage` que cachea por URL vía `ImageLoaderCache`.
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (CachedImagePhase) -> Content

    @State private var phase: CachedImagePhase

    init(url: URL?, @ViewBuilder content: @escaping (CachedImagePhase) -> Content) {
        self.url = url
        self.content = content
        // Hit síncrono en memoria desde el primer frame: en reload la imagen
        // cacheada ya está resuelta y no aparece el mini-flash del skeleton.
        if let url, let cached = ImageLoaderCache.shared.cachedImage(forKey: url.absoluteString) {
            _phase = State(initialValue: .success(Image(uiImage: cached)))
        } else {
            _phase = State(initialValue: .empty)
        }
    }

    var body: some View {
        content(phase)
            .animation(.easeOut(duration: 0.25), value: isResolved)
            .task(id: url) { await load() }
    }

    /// `true` cuando ya hay imagen o falló: dispara el crossfade desde el skeleton.
    private var isResolved: Bool {
        switch phase {
        case .empty:  return false
        default:      return true
        }
    }

    private func load() async {
        guard let url else {
            phase = .failure
            return
        }
        // Cache-hit en memoria: resuelve sin pasar por .empty (sin flash).
        if let cached = ImageLoaderCache.shared.cachedImage(forKey: url.absoluteString) {
            phase = .success(Image(uiImage: cached))
            return
        }
        phase = .empty
        if let image = await ImageLoaderCache.shared.image(for: url) {
            phase = .success(Image(uiImage: image))
        } else {
            phase = .failure
        }
    }
}
