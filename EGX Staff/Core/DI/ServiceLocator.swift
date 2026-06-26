import Foundation

@MainActor
final class ServiceLocator {
    private enum Registration {
        case factory(() -> Any)
        case lazySingleton(() -> Any)
    }

    private var registrations: [String: Registration] = [:]
    private var singletons: [String: Any] = [:]

    func registerLazySingleton<T>(
        _ type: T.Type = T.self,
        instanceName: String? = nil,
        factory: @escaping () -> T
    ) {
        let key = makeKey(type, name: instanceName)
        registrations[key] = .lazySingleton(factory)
    }

    func registerSingleton<T>(
        _ type: T.Type = T.self,
        instanceName: String? = nil,
        instance: T
    ) {
        let key = makeKey(type, name: instanceName)
        registrations[key] = .lazySingleton { instance }
        singletons[key] = instance
    }

    func registerFactory<T>(
        _ type: T.Type = T.self,
        instanceName: String? = nil,
        factory: @escaping () -> T
    ) {
        let key = makeKey(type, name: instanceName)
        registrations[key] = .factory(factory)
    }

    func resolve<T>(
        _ type: T.Type = T.self,
        instanceName: String? = nil
    ) -> T {
        let key = makeKey(type, name: instanceName)
        guard let registration = registrations[key] else {
            fatalError("ServiceLocator: missing registration for \(key)")
        }
        switch registration {
        case .factory(let factory):
            guard let instance = factory() as? T else {
                fatalError("ServiceLocator: factory returned wrong type for \(key)")
            }
            return instance
        case .lazySingleton(let factory):
            if let cached = singletons[key] as? T { return cached }
            guard let instance = factory() as? T else {
                fatalError("ServiceLocator: factory returned wrong type for \(key)")
            }
            singletons[key] = instance
            return instance
        }
    }

    // GetIt-style: sl<T>() / sl(T.self)
    func callAsFunction<T>(
        _ type: T.Type = T.self,
        instanceName: String? = nil
    ) -> T {
        resolve(type, instanceName: instanceName)
    }

    func isRegistered<T>(_ type: T.Type, instanceName: String? = nil) -> Bool {
        registrations[makeKey(type, name: instanceName)] != nil
    }

    func reset() {
        registrations.removeAll()
        singletons.removeAll()
    }

    private func makeKey<T>(_ type: T.Type, name: String?) -> String {
        let typeName = String(reflecting: type)
        return name.map { "\(typeName)|\($0)" } ?? typeName
    }
}

/// Global service locator — equivalent to `GetIt.I` / `sl` in Dart.
let sl = ServiceLocator()
